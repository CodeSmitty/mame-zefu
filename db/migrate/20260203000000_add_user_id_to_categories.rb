class AddUserIdToCategories < ActiveRecord::Migration[7.2]
  def up
    # Add user_id column to categories
    add_reference :categories, :user, foreign_key: true, null: true

    # Remove the old unique index on name
    remove_index :categories, :name

    # Add a composite unique index on user_id and name
    add_index :categories, [:user_id, :name], unique: true

    # Populate user_id for existing categories
    migrate_existing_categories

    # Make user_id non-nullable after data migration
    change_column_null :categories, :user_id, false
  end

  def down
    # Consolidate duplicate categories by name before restoring unique index
    consolidate_categories_for_down

    # Remove the composite index
    remove_index :categories, [:user_id, :name]

    # Re-add the unique index on name
    add_index :categories, :name, unique: true

    # Remove the user_id column
    remove_reference :categories, :user, foreign_key: true
  end

  private

  def migrate_existing_categories
    # Get all categories and the users who have recipes using them
    Category.find_each do |category|
      user_ids = category.recipes.pluck(:user_id).uniq

      if user_ids.empty?
        # Category has no recipes, delete it
        category.destroy
        next
      elsif user_ids.length == 1
        # Category is used by only one user, just set the user_id
        category.update_column(:user_id, user_ids.first)
      else
        # Category is shared by multiple users, duplicate it for each user
        first_user_id = user_ids.shift
        category.update_column(:user_id, first_user_id)

        # Create a new category for each remaining user
        user_ids.each do |user_id|
          new_category = Category.create!(
            name: category.name,
            user_id: user_id,
            created_at: category.created_at,
            updated_at: category.updated_at
          )

          # Update the recipes for this user to use the new category in a single SQL statement
          sql = <<~SQL.squish
            UPDATE categories_recipes
            SET category_id = $1
            FROM recipes
            WHERE recipes.id = categories_recipes.recipe_id
              AND recipes.user_id = $2
              AND categories_recipes.category_id = $3
          SQL
          ActiveRecord::Base.connection.exec_query(sql, 'SQL', [
            bind_param('new_category_id', new_category.id, ActiveRecord::Type::Integer.new),
            bind_param('user_id', user_id, ActiveRecord::Type::Integer.new),
            bind_param('category_id', category.id, ActiveRecord::Type::Integer.new)
          ])
        end
      end
    end
  end

  def consolidate_categories_for_down
    Category.group(:name).having('count(*) > 1').pluck(:name).each do |name|
      categories = Category.where(name:).order(:id).to_a
      canonical = categories.shift

      categories.each do |duplicate|
        sql = <<~SQL.squish
          UPDATE categories_recipes
          SET category_id = $1
          WHERE category_id = $2
        SQL
        ActiveRecord::Base.connection.exec_query(sql, 'SQL', [
          bind_param('canonical_id', canonical.id, ActiveRecord::Type::Integer.new),
          bind_param('duplicate_id', duplicate.id, ActiveRecord::Type::Integer.new)
        ])

        duplicate.destroy!
      end
    end
  end

  def bind_param(name, value, type)
    ActiveRecord::Relation::QueryAttribute.new(name, value, type)
  end
end
