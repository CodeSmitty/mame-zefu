module Recipes
  class Import
    class Delish < Base
      def recipe_name
        document
          .css('header h1')
          .text
      end

      def recipe_yield
        document
          .css('div.recipe-body dl div')[0]
          .css('dd span')
          .map { |e| e.text.strip }
          .select(&:present?)
          .join(' ')
      end

      def recipe_prep_time
        document
          .css('div.recipe-body dl div')[1]
          .css('dd span')
          .map { |e| e.text.strip }
          .select(&:present?)
          .join(' ')
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
    end
  end
end
