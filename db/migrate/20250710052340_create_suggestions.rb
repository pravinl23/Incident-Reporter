class CreateSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :suggestions do |t|
      t.text :content
      t.string :kind
      t.datetime :timestamp

      t.timestamps
    end
  end
end
