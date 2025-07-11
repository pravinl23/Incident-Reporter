require 'openai'

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

  # New method for function calling with GPT-4o-mini
  def analyze_with_function_calling(context_messages, incident_id)
    # Build context-aware prompt
    context = context_messages.join("\n")
    current = "#{@transcript_message['speaker']}: #{@transcript_message['text']}"
    
    messages = [
      {
        role: :system,
        content: "Analyze incident chat messages and identify actionable items."
      },
      {
        role: :user,
        content: <<~PROMPT
          Context: #{context}
          
          Current: #{current}
          
          Identify action items, trigger events, root causes, or missing metadata.
        PROMPT
      }
    ]
    
    # Define the function schema
    functions = [{
      name: "new_suggestion",
      description: "Create a new incident suggestion",
      parameters: {
        type: "object",
        properties: {
          kind: {
            type: "string",
            enum: ["action_item", "trigger_event", "root_cause_theory", "missing_metadata"],
            description: "The type of suggestion"
          },
          message: {
            type: "string",
            description: "The suggestion content"
          },
          confidence: {
            type: "number",
            minimum: 0,
            maximum: 1,
            description: "Confidence score (0-1)"
          },
          source_transcript_index: {
            type: "integer",
            description: "Index of the source message"
          }
        },
        required: ["kind", "message", "source_transcript_index"]
      }
    }]
    
    suggestions = []
    
    begin
      response = @client.chat.completions.create(
        model: "gpt-4o-mini",
        messages: messages,
        functions: functions,
        function_call: "auto",
        temperature: 0.3,
        max_tokens: 1000
      )
      
      if response.choices && response.choices.first.message.function_call
        function_call = response.choices.first.message.function_call
        
        if function_call.name == "new_suggestion"
          args = JSON.parse(function_call.arguments)
          
          suggestion = Suggestion.create!(
            content: args["message"],
            suggestion_type: args["kind"],
            source_transcript_index: args["source_transcript_index"] || @message_index,
            incident_id: incident_id,
            confidence: args["confidence"] || 0.8,
            status: 'new'
          )
          
          suggestions << suggestion
        end
      end
      
    rescue => e
      Rails.logger.error "AiSuggestionService error: #{e.message}"
    end
    
    suggestions
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
end 