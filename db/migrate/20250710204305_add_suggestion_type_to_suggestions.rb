class AddSuggestionTypeToSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_column :suggestions, :suggestion_type, :string
  end
end
