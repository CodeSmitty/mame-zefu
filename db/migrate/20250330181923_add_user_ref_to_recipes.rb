class AddUserRefToRecipes < ActiveRecord::Migration[7.2]
  def up
    Recipe.delete_all
    add_reference :recipes, :user, null: false, foreign_key: true
  end
  
  def down
    remove_reference :recipes, :user, null: false, foreign_key: true
  end
end
