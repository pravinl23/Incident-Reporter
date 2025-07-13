module Llms
  class SuggestJob < ApplicationJob
    queue_as :suggest
    
    sidekiq_options retry: 1, queue: :suggest
    
    def perform(message_data, message_index, incident_id, recent_messages = [])
      context_messages = recent_messages.last(8).map { |m| "#{m['speaker']}: #{m['text']}" }
      
      service = AiSuggestionService.new(message_data, message_index)
      suggestions = service.analyze_with_function_calling(context_messages, incident_id)
      
      if suggestions.any?
        ActionCable.server.broadcast(
          "incident_#{incident_id}_suggestions",
          {
            suggestions: suggestions.map { |s| 
              {
                id: s.id,
                content: s.content,
                suggestion_type: s.suggestion_type,
                status: s.status,
                confidence: s.confidence,
                source_transcript_index: s.source_transcript_index,
                accepted: s.accepted,
                duplicate_count: s.duplicate_count || 1
              }
            }
          }
        )
      end
      
    rescue => e
      Rails.logger.error "SuggestJob failed: #{e.message}"
      raise
    end
  end
end 