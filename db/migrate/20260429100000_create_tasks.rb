class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.references :church, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true
      t.references :assigned_user, null: true, foreign_key: { to_table: :users }
      t.string  :title, null: false
      t.text    :description
      t.integer :priority, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.datetime :due_at
      t.bigint :created_by, null: false

      t.timestamps
    end

    add_index :tasks, [ :church_id, :status, :due_at ]
  end
end
