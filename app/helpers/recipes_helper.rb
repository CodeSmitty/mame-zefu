module RecipesHelper
  def recipe_extraction_enabled?
    Recipes::Extraction.enabled?(current_user)
  end

  def ingredient_parsing_enabled?
    Feature.ingredient_parsing_enabled?(current_user)
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

  def parsed_ingredient_markup(item)
    return item unless ingredient_parsing_enabled?

    parsed = Recipes::Ingredient::Parser.new(item).parse || {}
    safe_join(parsed_ingredient_pieces(parsed, item), ' ')
  end

  private

  def parsed_ingredient_pieces(parsed, item)
    [quantity_piece(parsed), unit_piece(parsed), ingredient_piece(parsed, item)].compact
  end

  def quantity_piece(parsed)
    return if parsed[:quantity].blank?

    content_tag(:span, humanized_quantity(parsed[:quantity]),
                class: 'ingredient-quantity font-semibold tabular-nums')
  end

  def unit_piece(parsed)
    return if parsed[:unit].blank?

    content_tag(:span, parsed[:unit],
                class: 'ingredient-unit font-semibold font-mono')
  end

  def ingredient_piece(parsed, item)
    ingredient_text = parsed[:ingredient].presence || item

    content_tag(:span, ingredient_text, class: 'ingredient-name')
  end

  def humanized_quantity(quantity)
    Fractional.new(quantity, to_human: true).to_s(mixed_number: true)
  rescue StandardError
    quantity
  end

  def category_options(category_names)
    category_names
      .uniq(&:downcase)
      .sort_by(&:downcase)
      .map { |name| [name, name] }
  end
end
