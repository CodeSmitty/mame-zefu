class Categories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :name, null:false, index: { unique:true }
      t.timestamps
    end

    create_join_table :recipes, :categories do |t|
      t.index :recipe_id
      t.index :category_id
    end
  end
end
