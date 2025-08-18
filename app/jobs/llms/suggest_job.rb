module Llms
  class SuggestJob < ApplicationJob
    queue_as :suggest

    sidekiq_options retry: 1, queue: :suggest

    def perform(message_data, message_index, incident_id, recent_messages = [])
      Rails.logger.info "SuggestJob starting for message #{message_index}"

      context_messages = recent_messages.last(8).map { |m| "#{m['speaker']}: #{m['text']}" }

      service = AiSuggestionService.new(message_data, message_index)
      suggestions = service.analyze_with_function_calling(context_messages, incident_id)

      Rails.logger.info "SuggestJob completed for message #{message_index} with #{suggestions.length} suggestions"

      # Always broadcast completion, whether suggestions were generated or not
      completion_message = {
        type: "job_completed",
        message_index: message_index,
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

      Rails.logger.info "Broadcasting completion message: #{completion_message.inspect}"

      ActionCable.server.broadcast(
        "incident_#{incident_id}_suggestions",
        completion_message
      )

    rescue => e
      Rails.logger.error "SuggestJob failed for message #{message_index}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Broadcast failure so UI can still decrement counter
      failure_message = {
        type: "job_failed",
        message_index: message_index,
        error: e.message
      }

      Rails.logger.info "Broadcasting failure message: #{failure_message.inspect}"

      ActionCable.server.broadcast(
        "incident_#{incident_id}_suggestions",
        failure_message
      )

      raise
    end
  end
end
