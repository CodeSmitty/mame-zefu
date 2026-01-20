module Recipes
  class Import
    class Base
      def initialize(document, source = nil)
        @document = document
        @source = source
      end

      IMPORT_FIELDS = %w[
        name
        yield
        prep_time
        cook_time
        category_names
        description
        ingredients
        directions
        notes
        rating
        is_favorite
        source
        image_src
      ].freeze

      def recipe
        Recipe.new.tap do |recipe|
          recipe.source = source
          IMPORT_FIELDS.each { |field| set_recipe_field(recipe, field) }
        end
      end

      private

      def set_recipe_field(recipe, field)
        setter = "#{field}="
        getter = "recipe_#{field}"

        recipe.send(setter, send(getter)) if respond_to?(getter)
      rescue StandardError => e
        Rails.logger.error "Error setting #{field} in #{self.class}: #{e.class} - #{e.message}. Source: #{source}"
      end

      attr_reader :document, :source
    end
  end
end
