class CreateDepartments < ActiveRecord::Migration[8.1]
  def change
    create_table :departments do |t|
      t.references :church, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :color
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :departments, [ :church_id, :name ], unique: true
    add_index :departments, [ :church_id, :active ]
  end
end
