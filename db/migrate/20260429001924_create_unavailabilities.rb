class CreateUnavailabilities < ActiveRecord::Migration[8.1]
  def change
    create_table :unavailabilities do |t|
      t.references :church, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :reason
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :unavailabilities, [ :church_id, :user_id ]
  end
end
