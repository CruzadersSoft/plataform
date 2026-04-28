class CreateChurches < ActiveRecord::Migration[8.1]
  def change
    create_table :churches do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :legal_name
      t.string :email
      t.string :phone
      t.string :timezone, null: false, default: "America/Sao_Paulo"
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :churches, :slug, unique: true
    add_index :churches, :status
  end
end
