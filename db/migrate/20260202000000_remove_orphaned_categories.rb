class RemoveOrphanedCategories < ActiveRecord::Migration[7.2]
  def up
    # Delete categories that have no associated recipes
    execute <<-SQL
      DELETE FROM categories
      WHERE id NOT IN (
        SELECT DISTINCT category_id FROM categories_recipes
      )
    SQL
  end

  def down
    # No-op: Cannot restore deleted categories. This migration is one-way.
  end
end
