class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.references :church, null: false, foreign_key: true
      t.string  :title, null: false
      t.text    :body, null: false
      t.integer :audience_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.datetime :published_at
      t.bigint :created_by, null: false

      t.timestamps
    end
  end
end
