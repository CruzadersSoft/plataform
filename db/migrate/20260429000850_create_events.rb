class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :church, null: false, foreign_key: true
      t.references :department, foreign_key: true
      t.string :title, null: false
      t.integer :event_type, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :location
      t.integer :status, null: false, default: 0
      t.text :notes
      t.bigint :created_by

      t.timestamps
    end

    add_index :events, [ :church_id, :starts_at ]
  end
end
