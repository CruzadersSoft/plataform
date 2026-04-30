class AddReplacementResolutionToScheduleAssignments < ActiveRecord::Migration[8.1]
  def change
    add_reference :schedule_assignments,
      :replacement_assignment,
      foreign_key: { to_table: :schedule_assignments },
      index: true

    add_column :schedule_assignments, :replacement_resolved_by, :integer
    add_column :schedule_assignments, :replacement_resolved_at, :datetime
    add_index :schedule_assignments, :replacement_resolved_by
    add_foreign_key :schedule_assignments, :users, column: :replacement_resolved_by
  end
end
