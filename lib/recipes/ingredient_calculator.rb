module Recipes
  class IngredientCalculator
    attr_accessor :recipe

    def initialize(recipe)
      @recipe = recipe
    end

    def calculate_total_ingredients(recipe, multiplier)
      parser = Recipes::IngredientParser.new(recipe).parse_ingredients
      scaler = Recipes::IngredientScaler.new.scale_ingredients(parser, multiplier)
      converter = Recipes::UnitConverter.new.converter(scaler)

      converter.pluck { |ing| ing[:converted_description] }.join('/n')
    end
  end
end
