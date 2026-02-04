module RecipesHelper
  def category_select_options(recipe)
    existing_categories = Category.all.map { |c| [c.name, c.name] }
    pending_categories = (recipe.pending_category_names || []).map { |n| [n, n] }

    (existing_categories + pending_categories).uniq { |label, _value| label.to_s.downcase }
  end
end
