class AddConfidenceToSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_column :suggestions, :confidence, :float
  end
end
