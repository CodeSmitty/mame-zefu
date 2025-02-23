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
          .text[/(\d+ \w+)/, 1]
      end

      def recipe_prep_time
        prep_time = total_time.index('Prep Time')
        return nil unless prep_time
        total_time[prep_time + 1]
      end

      def recipe_cook_time
        cook_time = cook_time = total_time.index('Cook Time')
        return nil unless cook_time
        total_time[cook_time + 1]
      end

      def recipe_total_time
        document
          .css('div.time-unit')
          .text[/(\d+ \w+)/, 1]
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
          .css('div.recipe-time span')
          .map(&:text)
      end
    end
  end
end
