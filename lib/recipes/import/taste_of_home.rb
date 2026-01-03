module Recipes
  class Import
    class TasteOfHome < Base
      def recipe_name
        document
          .css('h2.recipe-title')
          .text
      end

      def recipe_image_url
        document
          .css('div.pch-featured-image figure.wp-caption > div.pch-overlay-icon-wrap img')
          .first
          &.attr('src')
      end

      def recipe_yield
        document
          .css('span.meta-wrap span')
          &.last
          &.text
      end

      def recipe_prep_time
        document
          .css('span.meta-wrap span')
          &.last
          &.text
      end

      def recipe_cook_time
        document
          .css('span.meta-wrap span')
          &.last
          &.text
      end

      def recipe_ingredients
        document
          .css('div.recipe-ingredients ul.ingredients-list li')
          .map(&:text)
          .join("\n")
      end

      def recipe_directions
        document
          .css('div.recipe-directions ol.directions-list li.direction-step')
          .map { |li| li.text.strip }
          .join("\n\n")
      end
    end
  end
end
