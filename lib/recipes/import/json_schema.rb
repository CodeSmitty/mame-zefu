module Recipes
  class Import
    class JsonSchema < Base
      def initialize(document, source = nil)
        super

        @recipe_json ||= find_recipe_json
      end

      def recipe_name
        recipe_json['name']
      end

      def recipe_image_src
        return if recipe_json['image'].blank?

        image_uri =
          recipe_json['image']
          .then { Array.wrap(_1) }
          .first
          .then { |image| image.is_a?(Hash) ? image['url'] : image }
          .then { |url| URI(url) }

        return unless image_uri.is_a?(URI::HTTP) || image_uri.is_a?(URI::HTTPS)

        image_uri.to_s
      end

      def recipe_yield
        recipe_json['recipeYield']
      end

      def recipe_prep_time
        parse_duration(recipe_json['prepTime'])
      end

      def recipe_cook_time
        parse_duration(recipe_json['cookTime'])
      end

      def recipe_total_time
        parse_duration(recipe_json['totalTime'])
      end

      def recipe_category_names
        (Array.wrap(recipe_json['recipeCategory']) + Array.wrap(recipe_json['recipeCuisine'])).compact_blank
      end

      def recipe_description
        return if recipe_json['description'].blank?

        CGI.unescapeHTML(recipe_json['description'])
      end

      def recipe_ingredients
        Array.wrap(recipe_json['recipeIngredient']).map { fractionalize(_1) }.join("\n")
      end

      def recipe_directions
        Array.wrap(recipe_json['recipeInstructions']).map do |instruction|
          handle_instruction(instruction)
        end.join("\n\n")
      end

      private

      attr_reader :recipe_json

      def handle_section(section)
        "#{section['name'].upcase}\n" +
          Array.wrap(section['itemListElement']).map do |item|
            handle_instruction(item)
          end.join("\n\n")
      end

      def handle_instruction(instruction)
        if instruction.is_a?(Hash)
          if instruction['@type'] == 'HowToSection'
            handle_section(instruction)
          elsif instruction['@type'] == 'HowToStep'
            instruction['text']
          end
        else
          instruction.to_s
        end
      end

      def fractionalize(str)
        str.split.map do |word|
          /^\d+\.\d+$/.match?(word) ? Fractional.new(word, to_human: true) : word
        end.join(' ')
      end

      def parse_duration(str)
        return if str.blank?

        return str unless str.start_with?('P')

        duration = ActiveSupport::Duration.parse(str)
        return if duration.zero?

        duration.inspect
      end

      def find_recipe_json
        recipe = document.css('script[type="application/ld+json"]').lazy.map do |script|
          deep_find_recipe(JSON.parse(script.text))
        end.find(&:present?)

        return recipe if recipe.present?

        raise NotFoundError, 'No JSON-LD recipe data found on the page'
      end

      def deep_find_recipe(object)
        case object
        when Hash
          return object if Array.wrap(object['@type']).include?('Recipe')

          object.values.find { |v| deep_find_recipe(v) }
        when Array
          object.find { |item| deep_find_recipe(item) }
        end
      end

      class NotFoundError < StandardError; end
    end
  end
end
