class Suggestion < ApplicationRecord
  # Attributes:
  # - content: :text (the suggestion itself, e.g., "Investigate database connection issues on Service A.")
  # - suggestion_type: :string (e.g., "action_item", "trigger_event", "root_cause_theory", "missing_metadata")
  # - source_transcript_index: :integer (index of the message that triggered it)
  # - status: :string (e.g., "new", "accepted", "dismissed")
  # - incident_id: :integer (to link to specific incident)
  # - confidence: :float (0.0 to 1.0 confidence score from AI)
  
  validates :content, presence: true
  validates :suggestion_type, presence: true, inclusion: { 
    in: %w[action_item trigger_event root_cause_theory missing_metadata] 
  }
  validates :status, inclusion: { in: %w[new accepted dismissed] }, allow_nil: true
  
  after_initialize :set_defaults
  after_create :print_suggestion
  
  private
  
  def set_defaults
    self.status ||= 'new'
  end

  def print_suggestion
    puts "**********************************************************************************************************************************************************************************************"
    puts "New suggestion created: #{content}"
  end
end
