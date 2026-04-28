class CreateChurchMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :church_memberships do |t|
      t.references :church, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :church_role, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :joined_at
      t.references :invited_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :church_memberships, [ :church_id, :user_id ], unique: true
    add_index :church_memberships, [ :church_id, :church_role, :status ]
  end
end
