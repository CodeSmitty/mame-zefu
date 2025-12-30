require 'down'

module Recipes
  class Import
    class AllRecipes < Base
      def recipe_name
        document
          .css('div.article-post-header h1')
          .text
      end

      def recipe_yield
        "Serves #{recipe_details['servings']}"
      end

      def recipe_prep_time
        recipe_details['prep_time']
      end

      def recipe_cook_time
        recipe_details['cook_time']
      end

      def recipe_ingredients
        document
          .css('ul.mm-recipes-structured-ingredients__list li.mm-recipes-structured-ingredients__list-item')
          .map { |li| li.text.strip }
          .join("\n")
      end

      def recipe_directions
        document
          .css('div.mm-recipes-steps__content ol > li > p')
          .map { |e| e.text.strip }
          .join("\n\n")
      end

      def recipe_image_url
        document
          .css('div.photo-dialog__page div#photo-dialog__item_1-0 img')
          .map { |e| e.attr('src').freeze }
          .join
      end

      private

      def recipe_details
        @recipe_details ||=
          document
          .css('div.mm-recipes-details__content div.mm-recipes-details__item div.mm-recipes-details__label')
          .map { |e| e.text.parameterize.underscore }
          .zip(
            document
            .css('div.mm-recipes-details__content div.mm-recipes-details__item div.mm-recipes-details__value')
            .map { |e| e.text.strip }
          ).to_h
      end
    end
  end
end
