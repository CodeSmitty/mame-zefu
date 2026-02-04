module RecipesHelper
  def category_select_options(recipe)
    user = recipe.user || current_user
    existing_categories = user.categories.pluck(:name)
    pending_categories = recipe.pending_category_names || []

    (existing_categories + pending_categories)
      .uniq(&:downcase)
      .map { |name| [name, name] }
  end
end
