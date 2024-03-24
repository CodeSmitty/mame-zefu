module Recipes
  class Import
    class TasteOfHome < Base
      def recipe_name
        document
          .css('h1.recipe-title')
          .text
      end

      def recipe_yield
        document
          .css('div.makes p')
          .text
      end

      def recipe_prep_time
        total_time[/Prep: (\d+ \w+)/, 1]
      end

      def recipe_cook_time
        total_time[/(?:Cook|Bake): (\d+ \w+)/, 1]
      end

      def recipe_total_time
        total_time[%r{Prep/Total Time: (\d+ \w+)}, 1]
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

      private

      def total_time
        document
          .css('div.total-time p')
          .text
      end
    end
  end
end
