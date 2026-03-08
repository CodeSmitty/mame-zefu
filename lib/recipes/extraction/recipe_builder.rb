# frozen_string_literal: true

module Recipes
  class Extraction
    class RecipeBuilder
      TEXT_FIELDS = %i[name yield prep_time cook_time total_time description].freeze

      def self.build(payload)
        source = payload.to_h.with_indifferent_access

        Recipe.new(
          text_attributes(source).merge(
            ingredients: ingredients_to_text(source[:ingredients]),
            directions: directions_to_text(source[:directions]),
            category_names: normalized_categories(source)
          )
        )
      end

      def self.text_attributes(source)
        TEXT_FIELDS.index_with { |field| source[field].to_s.strip }
      end
      private_class_method :text_attributes

      def self.ingredients_to_text(value)
        Array(value).map(&:to_s).map(&:strip).compact_blank.join("\n")
      end
      private_class_method :ingredients_to_text

      def self.directions_to_text(value)
        Array(value).map(&:to_s).map(&:strip).compact_blank.join("\n\n")
      end
      private_class_method :directions_to_text

      def self.normalized_categories(source)
        Array(source[:category_names]).map(&:to_s).map(&:strip).compact_blank
      end
      private_class_method :normalized_categories
    end
  end
end
