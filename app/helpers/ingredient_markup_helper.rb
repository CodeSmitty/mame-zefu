module IngredientMarkupHelper
  def parsed_ingredient_markup(item)
    return item unless ingredient_parsing_enabled?

    ingredient = Ingredient::Parser.new(item).parse || Ingredient.new(name: item)
    scaled = ingredient.scale(recipe_scale)
    content = safe_join(ingredient_pieces(scaled), ' ')

    current_user&.is_admin? ? ingredient_debug_markup(content, ingredient, item) : content
  end

  private

  def ingredient_pieces(ingredient)
    [quantity_piece(ingredient), unit_piece(ingredient), secondary_measurement_piece(ingredient),
     ingredient_piece(ingredient)].compact
  end

  def quantity_piece(ingredient)
    return if ingredient.formatted_quantity.blank?

    content_tag(:span, ingredient.formatted_quantity,
                class: 'ingredient-quantity font-semibold tabular-nums')
  end

  def unit_piece(ingredient)
    return if ingredient.formatted_unit.blank?

    content_tag(:span, ingredient.formatted_unit,
                class: 'ingredient-unit font-semibold font-mono')
  end

  def secondary_measurement_piece(ingredient)
    return if ingredient.formatted_secondary_measurement.blank?

    content_tag(:span, ingredient.formatted_secondary_measurement,
                class: 'ingredient-secondary-measurement font-semibold font-mono')
  end

  def ingredient_piece(ingredient)
    content_tag(:span, ingredient.name, class: 'ingredient-name')
  end
end
