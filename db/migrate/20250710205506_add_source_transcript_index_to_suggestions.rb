class AddSourceTranscriptIndexToSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_column :suggestions, :source_transcript_index, :integer
  end
end
