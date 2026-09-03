module IngredientMarkupHelper
  def parsed_ingredient_markup(item)
    return item unless ingredient_parsing_enabled?

    ingredient = Ingredient::Parser.new(item).parse || Ingredient.new(name: item)
    parsed_attributes = ingredient.attributes
    scale = recipe_scale
    scaled_attributes = scaled_attributes(parsed_attributes, scale) if scale && Rational(scale) != 1
    ingredient.scale(scale) if scale
    content = safe_join(ingredient_pieces(ingredient), ' ')

    ingredient_debug_markup(content, item, parsed_attributes, scaled_attributes, ingredient.attributes)
  end

  private

  def recipe_scale
    scale = params[:scale].presence
    return unless valid_scale?(scale)

    scale
  end

  def valid_scale?(scale)
    Rational(scale).positive?
  rescue ArgumentError, TypeError, ZeroDivisionError
    false
  end

  # The scaled quantity before UnitFormatter's unit conversion/rounding is
  # applied, for comparing against the final "best_fit" debug attributes.
  def scaled_attributes(attributes, multiplier)
    attributes.merge(
      'quantity' => scaled_rational(attributes['quantity'], multiplier),
      'quantity_max' => scaled_rational(attributes['quantity_max'], multiplier)
    )
  end

  def scaled_rational(value, multiplier)
    return value if value.blank?

    (Rational(value) * Rational(multiplier)).to_s
  rescue ArgumentError, TypeError, ZeroDivisionError
    value
  end

  def ingredient_debug_markup(content, original, parsed_attributes, scaled_attributes, best_fit_attributes)
    return content unless current_user&.is_admin?

    content_tag(:span, data: { controller: 'ingredient-debug' }) do
      safe_join([debug_toggle_button, content,
                 debug_panel(original, parsed_attributes, scaled_attributes, best_fit_attributes)])
    end
  end

  def debug_toggle_button
    icon = render('icons/micro/magnifying_glass', classes: '')

    content_tag(:button, icon, type: 'button',
                               class: 'ingredient-debug-toggle text-gray-500 align-middle me-1 cursor-pointer ' \
                                      'no-underline',
                               data: { action: 'click->ingredient-debug#toggle:stop' })
  end

  def debug_panel(original, parsed_attributes, scaled_attributes, best_fit_attributes)
    # Wrapped in an inline-block span so the ancestor <li>'s line-through decoration
    # (toggled by the strikethrough feature) doesn't paint through this block-level <pre>.
    # The "hidden" toggle class stays on the <pre> itself to avoid colliding with
    # "inline-block" on the same element (both are display utilities with equal
    # specificity, and Tailwind's generated order would let inline-block win).
    debug_data = debug_data(original, parsed_attributes, scaled_attributes, best_fit_attributes)

    content_tag(:span, class: 'inline-block') do
      content_tag(:pre, JSON.pretty_generate(debug_data),
                  class: 'ingredient-debug-panel hidden mt-1 p-2 text-xs bg-gray-100 rounded whitespace-pre-wrap',
                  data: { ingredient_debug_target: 'panel' })
    end
  end

  def debug_data(original, parsed_attributes, scaled_attributes, best_fit_attributes)
    {
      original:,
      parsed: parsed_attributes.compact,
      scaled: scaled_attributes&.compact,
      best_fit: best_fit_attributes.compact
    }.compact
  end

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
