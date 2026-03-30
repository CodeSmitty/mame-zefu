require_relative 'ingredient_constants'
require 'fractional'

module Recipes
  class IngredientScaler
    include IngredientConstants

    def scale_ingredients(parsed_ingredients, multiplier)
      parsed_ingredients.map do |parsed|
        scale_ingredient(parsed, multiplier)
      end
    end

    def scale_ingredient(parsed_ingredient, multiplier)
      scale_with_logic(parsed_ingredient, multiplier)
    end

    private

    def scale_with_logic(parsed, multiplier)
      return unscaled_result(parsed) if parsed[:quantity].nil?

      scaled_quantity = Fractional.new(parsed[:quantity].to_r * multiplier).to_s
      scaled_quantity_max = scale_max_quantity(parsed[:quantity_max], multiplier)

      parsed.merge(
        scaled_quantity: scaled_quantity,
        scaled_quantity_max: scaled_quantity_max,
        scaled_description: build_scaled_description(scaled_quantity, scaled_quantity_max, parsed),
        scale_applied: true
      )
    end

    def scale_max_quantity(quantity_max, multiplier)
      return nil unless quantity_max

      Fractional.new(quantity_max.to_r * multiplier).to_s
    end

    def build_scaled_description(scaled_quantity, scaled_quantity_max, parsed)
      if parsed[:unit] && scaled_quantity_max
        "#{scaled_quantity} to #{scaled_quantity_max} #{parsed[:unit]} #{parsed[:ingredient]}"
      elsif parsed[:unit]
        "#{scaled_quantity} #{parsed[:unit]} #{parsed[:ingredient]}"
      else
        "#{scaled_quantity} #{parsed[:ingredient]}"
      end.strip
    end

    def unscaled_result(parsed)
      parsed.merge(
        scaled_quantity: nil,
        scaled_quantity_max: nil,
        scaled_description: parsed[:original],
        scale_applied: false
      )
    end
  end
end
