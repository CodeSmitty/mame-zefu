module IngredientDebugHelper
  def debug_measurements(ingredient)
    parsed = ingredient.attributes
    scaled = scaled_attributes(parsed, recipe_scale)
    best_fit = ingredient.scale(recipe_scale).best_fit_attributes

    rounded = rounded_attributes(scaled || parsed, best_fit)

    { parsed:, scaled:, rounded:, best_fit: }.each_with_object({}) do |(key, value), hash|
      hash[key] = key == :parsed ? value : value&.except('name')
    end
  end

  private

  def scaled_attributes(attributes, multiplier)
    return if multiplier.blank? || multiplier == 1 || attributes['quantity'].blank?

    attributes.merge(
      'scale' => multiplier,
      # Duplicated from Ingredient::UnitFormatter initializer
      'quantity' => attributes['quantity'].to_r * multiplier.to_r,
      'quantity_max' => attributes['quantity_max']&.to_r&.*(multiplier.to_r)
    )
  end

  # The source attributes with quantity replaced by its equivalent in the
  # best-fit measurement, so it's comparable to the un-rounded original.
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
end
