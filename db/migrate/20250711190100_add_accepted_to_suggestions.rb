class AddAcceptedToSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_column :suggestions, :accepted, :boolean, default: false
  end
end
