class CreateDepartmentMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :department_memberships do |t|
      t.references :church, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :department_role, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :department_memberships, [ :church_id, :department_id, :status ], name: "idx_department_memberships_on_church_department_status"
    add_index :department_memberships, [ :department_id, :user_id ], unique: true
    add_index :department_memberships, [ :church_id, :user_id ]
  end
end
