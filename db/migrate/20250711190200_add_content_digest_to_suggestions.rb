class AddContentDigestToSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_column :suggestions, :content_digest, :string
    add_column :suggestions, :duplicate_count, :integer, default: 1
    add_index :suggestions, :content_digest
  end
end 