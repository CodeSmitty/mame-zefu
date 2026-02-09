require_relative 'ingredient_constants'
require "fractional"

class IngredientScaler
  include IngredientConstants

  def scale_ingredients(parsed_ingredients, multiplier = 2)
    parsed_ingredients.map do |parsed|
      scale_ingredient(parsed, multiplier)
    end
  end

  def scale_ingredient(parsed_ingredient, multiplier)
    ingredient = parsed_ingredient[:ingredient].to_s.downcase
    
    if should_scale?(ingredient)
      scale_with_logic(parsed_ingredient, multiplier)
    else
      dont_scale(parsed_ingredient)
    end
  end

  private

  def should_scale?(ingredient)
    !DO_NOT_SCALE.any? { |skip| ingredient.include?(skip) }
  end

  def scale_with_logic(parsed, multiplier)
    original_quantity = parsed[:quantity] || 1
    scaled_quantity = original_quantity * multiplier

    fraction_quantity = Fractional.new(scaled_quantity)
    scaled_quantity = fraction_quantity.to_s
    puts "Scaled quantity: #{scaled_quantity} (#{fraction_quantity.to_f})"
    
    scaled_description = if parsed[:unit]
      "#{scaled_quantity} #{parsed[:unit]} #{parsed[:ingredient]}"
    else
      "#{scaled_quantity} #{parsed[:ingredient]}"
    end.strip

    parsed.merge(
      scaled_quantity: scaled_quantity,
      scaled_description: scaled_description,
      scale_applied: true
    )

  end

  def dont_scale(parsed)
    parsed.merge(
      scaled_quantity: parsed[:quantity],
      scaled_description: parsed[:original],
      scale_applied: false
    )
  end
end