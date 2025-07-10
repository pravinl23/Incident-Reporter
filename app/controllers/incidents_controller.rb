class IncidentsController < ApplicationController
  def index
    # For now, redirect to the replay of the sample transcript
    redirect_to replay_incident_path(1)
  end
  
  def replay
    # Load the transcript data from the JSON file
    # In a real app, this would come from the database based on params[:id]
    transcript_file = Rails.root.join('db', 'transcript', 'rootly_takehome_transcript_80_no_timestamps.json')
    @transcript_data = JSON.parse(File.read(transcript_file))
    @messages = @transcript_data['meeting_transcript']
    
    # Calculate timing for 10x speed replay
    # 10 minutes = 600 seconds, compressed to 60 seconds
    total_duration = 60.0 # seconds
    @time_per_message = total_duration / @messages.length
    
    # For display purposes
    @incident_id = params[:id] || 1
    @total_messages = @messages.length
    @original_duration = "10 minutes"
    @replay_duration = "1 minute"
  end
end 