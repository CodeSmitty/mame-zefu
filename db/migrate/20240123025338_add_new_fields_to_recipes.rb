class AddNewFieldsToRecipes < ActiveRecord::Migration[7.0]
  def change
    add_column :recipes, :yield, :string
    add_column :recipes, :prep_time, :string
    add_column :recipes, :cook_time, :string
    add_column :recipes, :rating, :integer 
    add_column :recipes, :is_favorite, :boolean, default: false, null:false
    add_column :recipes, :description, :text
    add_column :recipes, :notes, :text
  end
end
