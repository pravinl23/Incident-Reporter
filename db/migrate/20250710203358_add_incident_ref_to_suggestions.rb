class AddIncidentRefToSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_reference :suggestions, :incident, null: false, foreign_key: true
  end
end
