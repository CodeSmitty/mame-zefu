require 'ingreedy'
require_relative 'ingredient_constants'

class IngredientParsing
  include IngredientConstants
  
  attr_accessor :recipe

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

    begin
      parsed = Ingreedy.parse(normalized)
      
      {
        original: ingredient,
        quantity: parsed.amount,
        unit: parsed.unit,
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