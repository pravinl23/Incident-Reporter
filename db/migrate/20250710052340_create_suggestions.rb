class CreateSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :suggestions do |t|
      t.text :content
      t.string :suggestion_type
      t.integer :source_transcript_index
      t.string :status
      t.integer :incident_id
      t.float :confidence

      t.timestamps
    end
    
    add_index :suggestions, :incident_id
    add_index :suggestions, :suggestion_type
    add_index :suggestions, :status
  end
end
