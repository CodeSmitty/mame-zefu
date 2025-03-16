module Recipes
  class Import
    class TasteOfHome < Base
      def recipe_name
        document
          .css('h2.recipe-title')
          .text
      end

      def recipe_yield
        document
          .css('div.yield span')
          &.last
          &.text
      end

      def recipe_prep_time
        document
          .css('div.prep span')
          &.last
          &.text
      end

      def recipe_cook_time
        document
          .css('div.cook span')
          &.last
          &.text
      end

      def recipe_ingredients
        document
          .css('div.recipe-ingredients ul.recipe-ingredients__list li')
          .map(&:text)
          .join("\n")
      end

      def recipe_directions
        document
          .css('div.recipe-directions ol.recipe-directions__list li.recipe-directions__item')
          .map { |li| li.css('span').text.strip }
          .join("\n\n")
      end
    end
  end
end
