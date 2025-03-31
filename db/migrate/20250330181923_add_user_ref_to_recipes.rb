class AddUserRefToRecipes < ActiveRecord::Migration[7.2]
  Recipe.delete_all
  def change
    add_reference :recipes, :user, null: false, foreign_key: true
  end
end
