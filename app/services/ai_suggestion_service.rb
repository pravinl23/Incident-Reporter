require 'openai'
require 'digest'

class AiSuggestionService
  def initialize(transcript_message, message_index)
    @transcript_message = transcript_message
    @message_index = message_index
    @client = OpenAI::Client.new
  end

  def analyze_and_suggest
    prompt = generate_prompt(@transcript_message['text'])
    response = call_llm_api(prompt)
    suggestions = parse_llm_response(response)
    
    # Create Suggestion records
    suggestions.map do |suggestion_params|
      Suggestion.create!(
        content: suggestion_params[:content],
        suggestion_type: suggestion_params[:suggestion_type],
        source_transcript_index: @message_index,
        incident_id: 1 # For now, using a default incident ID
      )
    end
  rescue => e
    []
  end

  # Advanced analysis with function calling
  def analyze_with_function_calling(context_messages, incident_id)
    context = context_messages.join("\n")
    current = "#{@transcript_message['speaker']}: #{@transcript_message['text']}"
    
    # First check for timeline events with regex
    timeline_suggestions = detect_timeline_events(current)
    
    # Then get AI suggestions
    ai_suggestions = get_ai_suggestions(context, current, incident_id)
    
    all_suggestions = timeline_suggestions + ai_suggestions
    
    # Deduplicate and merge
    deduplicated_suggestions = deduplicate_suggestions(all_suggestions, incident_id)
    
    deduplicated_suggestions
  end

  private

  def generate_prompt(text)
    <<~PROMPT
      Analyze this incident message and identify:
      - Action items (tasks to do later)
      - Trigger events (status changes)
      - Root cause theories
      - Missing metadata

      Return JSON array with type and content fields.
      Types: action_item, trigger_event, root_cause_theory, missing_metadata

      Message: "#{text}"
    PROMPT
  end

  def call_llm_api(prompt)
    response = @client.chat.completions.create(
      model: "gpt-3.5-turbo",
      messages: [{ 
        role: :user, 
        content: prompt 
      }],
      temperature: 0.2,
      max_tokens: 500
    )
    
    response.choices.first.message.content
  rescue => e
    nil
  end

  def parse_llm_response(response_text)
    return [] unless response_text.present?

    # Extract JSON from the response (sometimes LLMs add extra text)
    json_match = response_text.match(/\[.*\]/m)
    return [] unless json_match
    
    suggestions = JSON.parse(json_match[0])
    
    # Validate and normalize each suggestion
    suggestions.filter_map do |item|
      if item['type'].present? && item['content'].present?
        {
          suggestion_type: item['type'].downcase,
          content: item['content'].strip
        }
      else
        Rails.logger.warn("Malformed suggestion from LLM: #{item.inspect}")
        nil
      end
    end
  rescue JSON::ParserError => e
    []
  end

  def detect_timeline_events(message)
    suggestions = []
    text = message.downcase
    
    # Rollback detection
    if text.match?(/\b(rolling back|rollback\s+(started|initiated|beginning)|starting\s+rollback)\b/)
      suggestions << create_suggestion_hash(
        "Rollback initiated",
        "trigger_event",
        0.95
      )
    end
    
    # Resolution detection  
    if text.match?(/\b(resolved|fixed|issue\s+is\s+resolved|impact\s+(mitigated|resolved))\b/)
      suggestions << create_suggestion_hash(
        "Issue resolved/impact mitigated",
        "trigger_event", 
        0.90
      )
    end
    
    # Root cause confirmation
    if text.match?(/\b(root\s+cause|caused\s+by|identified\s+as|turns\s+out)\b/)
      suggestions << create_suggestion_hash(
        extract_root_cause(message),
        "root_cause_theory",
        0.85
      )
    end
    
    # Service impact detection
    if text.match?(/\b(affected|impacted|down|degraded).*\b(service|api|database|web|analytics)\b/)
      service = extract_affected_service(message)
      suggestions << create_suggestion_hash(
        "Record #{service} as affected service",
        "missing_metadata",
        0.80
      )
    end
    
    suggestions.compact
  end

  def get_ai_suggestions(context, current, incident_id)
    messages = [
      {
        role: :system,
        content: "Analyze incident messages and categorize findings precisely. Focus on timeline events, root causes, and actionable items."
      },
      {
        role: :user,
        content: "Context: #{context}\nCurrent: #{current}\n\nIdentify specific suggestions with appropriate types and realistic confidence."
      }
    ]
    
    functions = [{
      name: "new_suggestion",
      description: "Create a categorized incident suggestion",
      parameters: {
        type: "object",
        properties: {
          kind: {
            type: "string",
            enum: ["action_item", "trigger_event", "root_cause_theory", "missing_metadata"],
            description: "Precise categorization of the suggestion"
          },
          message: {
            type: "string",
            description: "Concise, specific suggestion content"
          },
          confidence: {
            type: "number",
            minimum: 0.5,
            maximum: 0.95,
            description: "Realistic confidence based on clarity and specificity"
          }
        },
        required: ["kind", "message", "confidence"]
      }
    }]
    
    suggestions = []
    
    begin
      response = @client.chat.completions.create(
        model: "gpt-4o-mini",
        messages: messages,
        functions: functions,
        function_call: "auto",
        temperature: 0.2,
        max_tokens: 800,
        logprobs: true,
        top_logprobs: 5
      )
      
      if response.choices && response.choices.first.message.function_call
        function_call = response.choices.first.message.function_call
        
        if function_call.name == "new_suggestion"
          args = JSON.parse(function_call.arguments)
          
          # Map logprobs to confidence if available
          adjusted_confidence = adjust_confidence_from_logprobs(
            args["confidence"], 
            response.choices.first.logprobs
          )
          
          suggestions << create_suggestion_hash(
            args["message"],
            args["kind"],
            adjusted_confidence
          )
        end
      end
      
    rescue => e
      Rails.logger.error "AI suggestion error: #{e.message}"
    end
    
    suggestions
  end

  def create_suggestion_hash(content, type, confidence)
    {
      content: content,
      suggestion_type: type,
      confidence: confidence,
      source_transcript_index: @message_index,
      content_digest: Digest::SHA256.hexdigest(content.downcase.strip)
    }
  end

  def deduplicate_suggestions(suggestions, incident_id)
    created_suggestions = []
    
    suggestions.each do |suggestion_data|
      digest = suggestion_data[:content_digest]
      
      # Check for existing suggestion with same digest
      existing = Suggestion.find_by(
        incident_id: incident_id,
        content_digest: digest
      )
      
      if existing
        # Increment duplicate count
        existing.update(duplicate_count: existing.duplicate_count + 1)
        created_suggestions << existing
      else
        # Apply similarity penalty
        adjusted_confidence = apply_similarity_penalty(
          suggestion_data[:content], 
          suggestion_data[:confidence],
          incident_id
        )
        
        suggestion = Suggestion.create!(
          content: suggestion_data[:content],
          suggestion_type: suggestion_data[:suggestion_type],
          source_transcript_index: suggestion_data[:source_transcript_index],
          incident_id: incident_id,
          confidence: adjusted_confidence,
          status: 'new',
          content_digest: digest
        )
        
        created_suggestions << suggestion
      end
    end
    
    created_suggestions
  end

  def apply_similarity_penalty(content, confidence, incident_id)
    recent_suggestions = Suggestion.where(incident_id: incident_id)
                                  .where('created_at > ?', 5.minutes.ago)
                                  .pluck(:content)
    
    # Simple similarity check - count common words
    content_words = content.downcase.split(/\W+/).reject(&:empty?)
    
    max_similarity = recent_suggestions.map do |recent_content|
      recent_words = recent_content.downcase.split(/\W+/).reject(&:empty?)
      common_words = (content_words & recent_words).length
      total_words = [content_words.length, recent_words.length].max
      
      total_words > 0 ? common_words.to_f / total_words : 0
    end.max || 0
    
    # Penalize confidence for high similarity
    if max_similarity > 0.7
      confidence * 0.6  # Heavy penalty
    elsif max_similarity > 0.5
      confidence * 0.8  # Moderate penalty
    else
      confidence
    end
  end

  def adjust_confidence_from_logprobs(base_confidence, logprobs)
    return base_confidence unless logprobs
    
    # Use average logprob to adjust confidence
    avg_logprob = logprobs.content&.map { |token| token.logprob }&.sum || 0
    
    if avg_logprob > -0.5
      [base_confidence * 1.1, 0.95].min
    elsif avg_logprob < -2.0
      [base_confidence * 0.8, 0.5].max
    else
      base_confidence
    end
  end

  def extract_root_cause(message)
    # Extract meaningful root cause from message
    text = message.downcase
    
    if text.include?("deploy")
      "Issue related to recent deployment"
    elsif text.include?("database") || text.include?("db")
      "Database-related root cause identified"
    elsif text.include?("memory") || text.include?("cpu")
      "Resource exhaustion identified as cause"
    else
      "Root cause identified in discussion"
    end
  end

  def extract_affected_service(message)
    text = message.downcase
    
    if text.include?("web")
      "Web service"
    elsif text.include?("analytics")
      "Analytics service"
    elsif text.include?("api")
      "API service"
    elsif text.include?("database") || text.include?("db")
      "Database"
    else
      "Service"
    end
  end
end 