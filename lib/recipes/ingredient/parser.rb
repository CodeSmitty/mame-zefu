require 'ingreedy'
require_relative 'fraction_normalizer'

module Recipes
  module Ingredient
    class Parser
      attr_reader :ingredient

      def self.parse_ingredients(recipe)
        # Splits multi-line ingredient text into individual non-empty lines.
        recipe.ingredients.to_s.split(/[\r\n]+/).map(&:strip).reject(&:empty?).map do |ingredient|
          new(ingredient).parse
        end.compact
      end

      def initialize(ingredient)
        @ingredient = ingredient.to_s.strip
      end

      def parse
        return if ingredient.empty?

        # Matches free-form "to taste" lines that should not be scaled.
        return unscalable_parse(ingredient) if ingredient.match?(/\bto taste\b/i)

        container_result = try_container_parse(ingredient)
        return container_result if container_result

        parse_normalized_ingredient(ingredient)
      end

      private

      def parse_normalized_ingredient(ingredient)
        normalized = normalized_ingredient(ingredient)
        try_range_parse(normalized, ingredient) ||
          try_ingreedy(normalized, ingredient) ||
          try_regex_fallback(normalized, ingredient) ||
          default_parse(ingredient)
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
        FractionNormalizer.normalize(ingredient)
      end

      def try_ingreedy(normalized, ingredient)
        parsed = Ingreedy.parse(normalized_for_ingreedy(normalized))
        return nil if parsed.amount.nil?

        {
          original: ingredient,
          quantity: parsed.amount&.to_s || '1/1',
          unit: parsed.unit&.to_s,
          ingredient: normalize_ingredient_text(parsed.ingredient, parsed.unit&.to_s)
        }
      rescue Ingreedy::ParseFailed
        nil
      end

      def normalized_for_ingreedy(normalized)
        # Accept common ingredient phrasing like "2 tablespoons, minced parsley" by
        # removing the comma that separates the parsed unit from the ingredient text.
        normalized.gsub(%r{\A([\d\s/.]+)\s+([[:alpha:]]+),\s+}i, '\\1 \\2 ')
      end

      def normalize_ingredient_text(ingredient_text, unit)
        return ingredient_text if unit.blank?

        ingredient_text.sub(/\A\s*,\s*/, '').sub(/\A\s+/, '').sub(/\A,/, '').strip
      end

      def try_range_parse(normalized, ingredient)
        # Matches ranges like "1-2 tsp sugar" or "1 to 2 tsp sugar".
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
        # Matches container forms like "1 (14 oz) can tomatoes".
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
        # Matches a leading numeric quantity followed by remaining ingredient text.
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
    end
  end
end
