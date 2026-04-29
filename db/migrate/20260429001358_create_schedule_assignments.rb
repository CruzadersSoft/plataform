class CreateScheduleAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_assignments do |t|
      t.references :church, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :event_requirement, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :response_at
      t.text :decline_reason
      t.bigint :assigned_by

      t.timestamps
    end

    add_index :schedule_assignments, [ :church_id, :event_id, :status ]
    add_index :schedule_assignments, [ :event_requirement_id, :user_id ], unique: true
  end
end
