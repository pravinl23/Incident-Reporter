class CreateIncidents < ActiveRecord::Migration[8.0]
  def change
    create_table :incidents do |t|
      t.string :title
      t.string :status
      t.string :severity

      t.timestamps
    end
  end
end
