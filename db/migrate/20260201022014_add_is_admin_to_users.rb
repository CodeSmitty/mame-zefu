class AddIsAdminToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_admin, :boolean
  end
end
