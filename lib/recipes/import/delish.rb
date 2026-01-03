module Recipes
  class Import
    class Delish < Base
      def recipe_name
        document
          .css('header h1')
          .text
      end

      def recipe_image_url
        document
          .css('div.content-lead-image > div > picture > img')
          .map { |e| e.attr('src').freeze }
          .join
      end

      def recipe_yield
        recipe_details['yields']
      end

      def recipe_prep_time
        recipe_details['prep_time']
      end

      def recipe_total_time
        recipe_details['total_time']
      end

      def recipe_ingredients
        document
          .css('div.ingredients-body ul.ingredient-lists li')
          .map(&:text)
          .join("\n")
      end

      def recipe_directions
        document
          .css('div.recipe-body ul.directions ol li')
          .map { |li| li.xpath('text()') }
          .join("\n\n")
      end

      private

      def recipe_details
        @recipe_details ||=
          document
          .css('div.recipe-body dl dt')
          .map { |e| e.text.parameterize.underscore }
          .zip(
            document
            .css('div.recipe-body dl dd')
            .map { |e| e.css('span').text.strip }
          ).to_h
      end
    end
  end
end
