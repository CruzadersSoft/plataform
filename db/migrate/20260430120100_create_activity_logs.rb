class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :church, null: false, foreign_key: true
      t.references :actor_user, null: false, foreign_key: { to_table: :users }
      t.string :entity_type, null: false
      t.integer :entity_id, null: false
      t.string :action, null: false
      t.json :metadata_json, null: false, default: {}
      t.string :ip_address

      t.datetime :created_at, null: false
    end

    add_index :activity_logs, [ :church_id, :entity_type, :entity_id ]
    add_index :activity_logs, [ :church_id, :action, :created_at ]
  end
end
