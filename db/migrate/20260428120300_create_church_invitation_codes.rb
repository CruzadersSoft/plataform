class CreateChurchInvitationCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :church_invitation_codes do |t|
      t.references :church, null: false, foreign_key: true
      t.string :code, null: false
      t.integer :church_role, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :expires_at
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :church_invitation_codes, :code, unique: true
    add_index :church_invitation_codes, [ :church_id, :status ]
  end
end
