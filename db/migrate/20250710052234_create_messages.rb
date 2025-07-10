class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.text :content
      t.datetime :timestamp

      t.timestamps
    end
  end
end
