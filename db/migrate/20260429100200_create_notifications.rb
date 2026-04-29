class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :church, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string  :notification_type, null: false
      t.string  :title, null: false
      t.text    :body
      t.string  :related_type
      t.bigint  :related_id
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [ :church_id, :user_id, :read_at ]
  end
end
