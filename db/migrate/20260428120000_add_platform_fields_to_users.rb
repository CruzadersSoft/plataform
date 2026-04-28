class AddPlatformFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :platform_role, :integer, null: false, default: 0
    add_column :users, :status, :integer, null: false, default: 0
  end
end
