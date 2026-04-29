class CreateEventRequirements < ActiveRecord::Migration[8.1]
  def change
    create_table :event_requirements do |t|
      t.references :church, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :skill, foreign_key: true
      t.string :role_name, null: false
      t.integer :required_quantity, null: false
      t.integer :priority, default: 1
      t.text :notes

      t.timestamps
    end

    add_index :event_requirements, [ :church_id, :event_id ]
  end
end
