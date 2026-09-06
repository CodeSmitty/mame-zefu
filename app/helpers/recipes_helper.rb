module RecipesHelper
  def recipe_extraction_enabled?
    Recipes::Extraction.enabled?(current_user)
  end

  def ingredient_parsing_enabled?
    Feature.ingredient_parsing_enabled?(current_user)
  end

  def recipe_scaling_enabled?
    Feature.recipe_scaling_enabled?(current_user)
  end

  def recipe_scale
    scale = Integer(params[:scale], exception: false)
    return 1 unless scale&.positive? && scale.even?

    scale
  end

  def recipe_scaled?
    recipe_scale != 1
  end

  def previous_recipe_scale
    case recipe_scale
    when 1 then nil
    when 2 then 1
    else recipe_scale - 2
    end
  end

  def next_recipe_scale
    recipe_scale == 1 ? 2 : recipe_scale + 2
  end

  def recipe_draft_key(recipe)
    draft_id = recipe.persisted? ? recipe.id : 'new'

    "user:#{current_user.id}:recipe:#{draft_id}"
  end

  def category_select_options(recipe)
    user = recipe.user || current_user
    existing_categories = user.categories.pluck(:name)
    pending_categories = recipe.pending_category_names || []

    category_options(existing_categories + pending_categories)
  end

  def category_filter_options(user = current_user)
    category_options(user.categories.pluck(:name))
  end

  private

  def category_options(category_names)
    category_names
      .uniq(&:downcase)
      .sort_by(&:downcase)
      .map { |name| [name, name] }
  end
end
