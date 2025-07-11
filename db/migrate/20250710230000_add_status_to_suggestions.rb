class AddStatusToSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_column :suggestions, :status, :string, default: 'new'
  end
end 