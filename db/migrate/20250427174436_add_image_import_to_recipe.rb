class AddImageImportToRecipe < ActiveRecord::Migration[7.2]
  def change
    add_column :recipes, :image, :string
  end
end
