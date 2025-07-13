class AddFeedbackToSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_column :suggestions, :feedback, :string
  end
end
