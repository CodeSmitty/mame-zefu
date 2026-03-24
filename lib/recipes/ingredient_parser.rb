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
      return unscalable_parse(ingredient) if ingredient.match?(/\bto taste\b/i)

      container_result = try_container_parse(ingredient)
      return container_result if container_result

      normalized = normalized_ingredient(ingredient)
      range_result = try_range_parse(normalized, ingredient)
      return range_result if range_result

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
      normalize_fractions(ingredient)
    end

    def try_ingreedy(normalized, ingredient)
      parsed = Ingreedy.parse(normalized)
      return nil if parsed.amount.nil?

      {
        original: ingredient,
        quantity: parsed.amount&.to_s || '1/1',
        unit: parsed.unit&.to_s,
        ingredient: parsed.ingredient
      }
    rescue Ingreedy::ParseFailed
      nil
    end

    def try_range_parse(normalized, ingredient)
      match = normalized.match(%r{\A([\d/.]+)\s*(?:to|-)\s*([\d/.]+)\s+([^\s]+)\s+(.+)\z}i)
      return unless match

      {
        original: ingredient,
        quantity: match[1].to_r.to_s,
        quantity_max: match[2].to_r.to_s,
        unit: match[3],
        ingredient: match[4].strip
      }
    end

    def try_container_parse(ingredient)
      match = ingredient.match(/\A(\d+)\s+(\(.+\)\s+.+)\z/)
      return unless match

      {
        original: ingredient,
        quantity: "#{match[1]}/1",
        unit: nil,
        ingredient: match[2].strip
      }
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
      normalized_text = text.gsub(/(\d)(#{FRACTION_PATTERN})/) do
        "#{::Regexp.last_match(1)} #{FRACTION_MAP[::Regexp.last_match(2)]}"
      end
      normalized_text = normalized_text.gsub(FRACTION_PATTERN) { |match| FRACTION_MAP[match] }
      normalized_text.gsub(%r{(\d+)[\s-]+(\d+)/(\d+)}) do
        whole = ::Regexp.last_match(1).to_i
        num   = ::Regexp.last_match(2).to_i
        den   = ::Regexp.last_match(3).to_i
        "#{(whole * den) + num}/#{den}"
      end
    end
  end
end
