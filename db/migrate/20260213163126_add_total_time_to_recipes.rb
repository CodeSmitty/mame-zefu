class AddTotalTimeToRecipes < ActiveRecord::Migration[7.2]
  def change
    add_column :recipes, :total_time, :string
  end
end
