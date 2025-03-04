module Recipes
  class Import
    class FoodAndWine < Base
      def recipe_name
        document
          .css('h1.article-heading')
          .text
      end

      def recipe_yield
        recipe_details['yield']
      end

      def recipe_total_time
        recipe_details['total_time']
      end

      def recipe_ingredients
        document
          .css('ul.mm-recipes-structured-ingredients__list li p > span')
          .map { |t| t.text.strip }
          .compact_blank
          .join("\n")
      end

      def recipe_directions
        document
          .css('li.mntl-sc-block-group--LI > p')
          .map { |t| t.text.strip }
          .compact_blank
          .join("\n\n")
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
