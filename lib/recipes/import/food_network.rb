module Recipes
  class Import
    class FoodNetwork < Base
      def recipe_name
        document
          .css('h1')
          .text
          .strip
      end

      def recipe_image_url
        document
          .css('section.o-RecipeLead img')
          .first
          &.attr('src')
          &.then { |src| src.insert(0, 'https://') }
      end

      def recipe_yield
        recipe_details['yield']
      end

      def recipe_prep_time
        recipe_details['prep'].presence || recipe_details['active']
      end

      def recipe_cook_time
        recipe_details['cook'].presence || recipe_details['total']
      end

      def recipe_ingredients # rubocop:disable Metrics
        document
          .css('section.o-Ingredients div.o-Ingredients__m-Body')
          .children
          .reduce('') do |text, node|
            next text unless node.element?

            if node.name == 'p'
              next text if node.classes.include?('o-Ingredients__a-Ingredient--SelectAll')

              text << node
                      .css('span.o-Ingredients__a-Ingredient--CheckboxLabel')
                      .text
                      .concat("\n")
            elsif node.name == 'h3' && node.text.present?
              text << "\n" if text.present?

              text << "#{node.text.strip.upcase}\n"
            end

            text
          end
      end

      def recipe_directions # rubocop:disable Metrics
        document
          .css('section.o-Method div.o-Method__m-Body')
          .children
          .reduce('') do |text, node|
            next text unless node.element?

            if node.name == 'ol'
              text << node.children.map { |e| e.text.strip }.compact_blank.join("\n\n")
            elsif node.name == 'h3' && node.text.present?
              text << "\n\n" if text.present?

              text << "#{node.text.strip.upcase}\n"
            end

            text
          end
      end

      private

      def recipe_details
        @recipe_details ||=
          document
          .css('div.recipeInfo li')
          .each_with_object({}) do |element, details|
            label = element.css('span.o-RecipeInfo__a-Headline').text.parameterize.underscore
            value = element.css('span.o-RecipeInfo__a-Description').text.strip
            details[label] = value
          end
      end
    end
  end
end
