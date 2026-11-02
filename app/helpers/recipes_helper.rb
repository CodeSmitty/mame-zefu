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

  FRACTIONAL_RECIPE_SCALES = { '0.5' => 0.5, '1.5' => 1.5 }.freeze

  def recipe_scale
    return FRACTIONAL_RECIPE_SCALES[params[:scale].to_s] if FRACTIONAL_RECIPE_SCALES.key?(params[:scale].to_s)

    scale = Integer(params[:scale], exception: false)
    return 1 unless scale&.positive? && scale.even?

    scale
  end

  PREVIOUS_RECIPE_SCALES = { 0.5 => nil, 1 => 0.5, 1.5 => 1, 2 => 1.5 }.freeze
  NEXT_RECIPE_SCALES = { 0.5 => 1, 1 => 1.5, 1.5 => 2 }.freeze

  def previous_recipe_scale
    PREVIOUS_RECIPE_SCALES.fetch(recipe_scale) { recipe_scale - 2 }
  end

  def next_recipe_scale
    NEXT_RECIPE_SCALES.fetch(recipe_scale) { recipe_scale + 2 }
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
