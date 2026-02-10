require 'ingreedy'
require_relative 'ingredient_constants'

module Recipes
  class IngredientParser
    include IngredientConstants
    
    attr_accessor :recipe

    def initialize(recipe)
      @recipe = recipe
    end

    def parse_ingredients
      ingredients_text = recipe.ingredients.to_s
      ingredients = ingredients_text.split(/[\r\n]+/).map(&:strip).reject(&:empty?)

      ingredients.map do |ingredient|
        parse_single_ingredient(ingredient)
      end.compact
    end

    private

    def parse_single_ingredient(ingredient)
      normalized = normalize_fractions(ingredient)

      if ingredient.match(/^\d+\s+\(\d+\s*oz\)/i)
        match = ingredient.match(/^(\d+)\s+(.+)/)
        return {
          original: ingredient,
          quantity: "#{match[1]}/1",
          unit: nil,
          ingredient: match[2]
        }
      end
      
      begin
        parsed = Ingreedy.parse(normalized)

        {
          original: ingredient,
          quantity: parsed.amount ?  parsed.amount.to_s : nil,
          unit: parsed.unit ? parsed.unit.to_s : nil,
          ingredient: parsed.ingredient
        }
      rescue Ingreedy::ParseFailed
        {
          original: ingredient,
          quantity: nil,
          unit: nil,
          ingredient: ingredient
        }
      end
    end

    def normalize_fractions(text)
      normalized = text.dup
      FRACTION_MAP.each do |unicode, replacement|
        normalized.gsub!(unicode, replacement)
      end
      normalized
    end
  end
end
