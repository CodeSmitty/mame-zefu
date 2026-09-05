module IngredientMarkupHelper
  include IngredientDebugHelper

  def parsed_ingredient_markup(item)
    return item unless ingredient_parsing_enabled?

    ingredient = Ingredient::Parser.new(item).parse || Ingredient.new(name: item)
    parsed_attributes = ingredient.attributes
    scale = recipe_scale
    scaled_attributes = scaled_attributes(parsed_attributes, scale) if scale && Rational(scale) != 1
    ingredient.scale(scale) if scale
    content = safe_join(ingredient_pieces(ingredient), ' ')

    measurements = debug_measurements(ingredient, parsed_attributes, scaled_attributes, scale)
    ingredient_debug_markup(content, item, measurements)
  end

  private

  def debug_measurements(ingredient, parsed_attributes, scaled_attributes, scale)
    best_fit_attributes = ingredient.best_fit_attributes
    source_attributes = scaled_attributes || parsed_attributes

    {
      parsed: parsed_attributes,
      scale: (scale if scaled_attributes),
      scaled: scaled_attributes&.except('name'),
      rounded: rounded_attributes(source_attributes, best_fit_attributes)&.except('name'),
      best_fit: best_fit_attributes.except('name')
    }
  end

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

  # The source attributes with quantity replaced by its equivalent in the
  # best-fit measurement, so it's comparable to the un-rounded original.
  # Reuses Ingredient::UnitFormatter's own conversion math (no reimplementation).
  def rounded_attributes(source_attributes, best_fit_attributes)
    return unless formattable_measurement?(source_attributes)

    base_amount = Ingredient::UnitFormatter.total_base_amount(**best_fit_attributes.symbolize_keys.slice(
      :quantity, :unit, :quantity_secondary, :unit_secondary
    ))
    rounded_quantity = Ingredient::UnitFormatter.quantity_in(unit: source_attributes['unit'], base_amount:)
    return unless rounded_quantity
    return if Rational(source_attributes['quantity']) == rounded_quantity

    source_attributes.merge('quantity' => Ingredient::UnitFormatter.rational_string(rounded_quantity)).compact
  end

  def formattable_measurement?(attributes)
    Rational(attributes['quantity'])
    true
  rescue ArgumentError, TypeError, ZeroDivisionError
    false
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
