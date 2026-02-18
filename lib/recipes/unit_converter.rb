require_relative 'ingredient_constants'

module Recipes
  class UnitConverter
    include IngredientConstants

    def converter(scaled_ingredients)
      scaled_ingredients.each do |ingredient|
        puts "ingredient: #{ingredient}"
        puts "_" * 20
        puts "ingredient unit: #{ingredient[:unit]}"
        puts "_" * 20
        puts "ingredient quantity: #{ingredient[:quantity]}"
      end
    end

    private

  end
end
