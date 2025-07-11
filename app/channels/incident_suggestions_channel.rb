class IncidentSuggestionsChannel < ApplicationCable::Channel
  def subscribed
    incident_id = params[:incident_id]
    stream_from "incident_#{incident_id}_suggestions"
    
    Rails.logger.info "Client subscribed to incident_#{incident_id}_suggestions"
  end

  def unsubscribed
    # Cleanup when client disconnects
    Rails.logger.info "Client unsubscribed from incident suggestions"
  end
  
  # Optional: Allow clients to request suggestion status
  def request_status(data)
    incident_id = data['incident_id']
    pending_count = Sidekiq::Queue.new('suggest').size
    
    transmit({
      type: 'status',
      pending_jobs: pending_count,
      timestamp: Time.current.to_i
    })
  end
end 