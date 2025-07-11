class IncidentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:analyze_message, :clear_suggestions, :suggestions]
  
  def index
    redirect_to replay_incident_path(1)
  end
  
  def replay
    transcript_file = Rails.root.join('db', 'transcript', 'rootly_takehome_transcript_80_no_timestamps.json')
    @transcript_data = JSON.parse(File.read(transcript_file))
    @messages = @transcript_data['meeting_transcript']
    
    total_duration = 60.0
    @time_per_message = total_duration / @messages.length
    
    @incident_id = params[:id] || 1
    @total_messages = @messages.length
    @original_duration = "10 minutes"
    @replay_duration = "1 minute"
  end
  
  def analyze_message
    message = params.require(:message).permit(:speaker, :text).to_h
    index = params.require(:index).to_i
    incident_id = params[:id].to_i
    
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    
    if HeuristicFilter.pass?(message['text'])
      recent_messages = get_recent_messages(index)
      
      Llms::SuggestJob.perform_later(
        message.to_h, 
        index, 
        incident_id,
        recent_messages
      )
      
      filter_time = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(2)
      
      render json: { 
        status: 'enqueued',
        filter_time_ms: filter_time,
        message: 'Processing suggestion in background'
      }
    else
      filter_time = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(2)
      
      render json: { 
        status: 'filtered',
        filter_time_ms: filter_time,
        suggestions: [] 
      }
    end
  rescue => e
    render json: { status: 'error', error: e.message }
  end
  
  def clear_suggestions
    Suggestion.where(incident_id: params[:id]).destroy_all
    render json: { status: 'ok' }
  end
  
  def suggestions
    suggestions = Suggestion.where(incident_id: params[:id]).order(:created_at)
    render json: { suggestions: suggestions }
  end
  
  private
  
  def get_recent_messages(current_index)
    transcript_file = Rails.root.join('db', 'transcript', 'rootly_takehome_transcript_80_no_timestamps.json')
    transcript_data = JSON.parse(File.read(transcript_file))
    messages = transcript_data['meeting_transcript']
    
    start_idx = [0, current_index - 8].max
    end_idx = current_index - 1
    
    return [] if end_idx < 0
    
    messages[start_idx..end_idx] || []
  end
end 