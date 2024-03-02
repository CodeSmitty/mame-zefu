module Recipes
  class Import
    class Base
      def initialize(document)
        @document = document
      end

      IMPORT_FIELDS = %w[name yield prep_time cook_time description ingredients directions notes].freeze

      def recipe
        Recipe.new.tap do |recipe|
          IMPORT_FIELDS.each do |field|
            setter = "#{field}="
            getter = "recipe_#{field}"
            recipe.send(setter, send(getter)) if respond_to?(getter)
          end
        end
      end

      private

      attr_reader :document
    end
  end
end
