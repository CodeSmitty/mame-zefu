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

    def parse_single_ingredient(ingredient)
      return unscalable_parse(ingredient) if contains_to_taste?(ingredient)

      normalized = normalized_ingredient(ingredient)
      ingreedy_result = try_ingreedy(normalized, ingredient)
      return ingreedy_result if ingreedy_result

      try_regex_fallback(normalized, ingredient) || default_parse(ingredient)
    end

    def unscalable_parse(ingredient)
      {
        original: ingredient,
        quantity: nil,
        unit: nil,
        ingredient: ingredient,
        unscalable: true
      }
    end

    def normalized_ingredient(ingredient)
      normalize_imprecise_units(normalize_fractions(ingredient))
    end

    def try_ingreedy(normalized, ingredient)
      parsed = Ingreedy.parse(normalized)
      {
        original: ingredient,
        quantity: parsed.amount&.to_s || '1/1',
        unit: parsed.unit&.to_s,
        ingredient: parsed.ingredient
      }
    rescue Ingreedy::ParseFailed
      nil
    end

    def try_regex_fallback(normalized, ingredient)
      match = normalized.match(%r{\A([\d\s/.]+)\s+(.+)})
      return unless match

      {
        original: ingredient,
        quantity: match[1].strip.to_r.to_s,
        unit: nil,
        ingredient: match[2].strip
      }
    end

    def default_parse(ingredient)
      {
        original: ingredient,
        quantity: '1/1',
        unit: nil,
        ingredient: ingredient
      }
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

    def normalize_imprecise_units(text)
      text.gsub(/\bpinch\b/i, '1/8 teaspoon')
          .gsub(/\bdash\b/i, '1/8 teaspoon')
          .gsub(/\bsmidgen\b/i, '1/32 teaspoon')
    end

    def contains_to_taste?(text)
      text.match?(/\bto taste\b/i)
    end
  end
end
