require 'ingreedy'
require_relative 'ingredient_constants'

module Recipes
  class IngredientParser
    include IngredientConstants

    attr_accessor :recipe

    FRACTION_PATTERN = Regexp.union(FRACTION_MAP.keys)

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

    def parse_single_ingredient(ingredient) # rubocop:disable Metrics/MethodLength
      normalized = normalize_fractions(ingredient)
      if ingredient.match(%r{^\d+\s+([a-z]+)?\s*\(\s*[\d/-]+\s*(oz|lb)\s*\)}i)
        match = ingredient.match(/^(\d+)\s+(.+)/)
        return {
          original: ingredient,
          quantity: "#{match[1]}/1",
          unit: nil,
          ingredient: match[2]
        }
      else
        Rails.logger.debug { "No match for pattern in ingredient: '#{ingredient}'" }
      end

      begin
        parsed = Ingreedy.parse(normalized)

        {
          original: ingredient,
          quantity: parsed.amount&.to_s,
          unit: parsed.unit&.to_s,
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
      normalized_text = text.gsub(FRACTION_PATTERN) do |match|
        FRACTION_MAP[match]
      end
      normalized_text.gsub(%r{(\d+)[\s-]+(\d+)/(\d+)}) do
        whole = ::Regexp.last_match(1).to_i
        num   = ::Regexp.last_match(2).to_i
        den   = ::Regexp.last_match(3).to_i
        "#{(whole * den) + num}/#{den}"
      end
    end
  end
end
