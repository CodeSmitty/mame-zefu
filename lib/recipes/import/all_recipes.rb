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
          .css('ul.mntl-structured-ingredients__list li.mntl-structured-ingredients__list-item')
          .map { |li| li.text.strip }
          .join("\n")
      end

      def recipe_directions
        document
          .css('div.recipe__steps-content li > p')
          .map { |e| e.text.strip }
          .join("\n\n")
      end

      private

      def recipe_details
        @recipe_details ||=
          document
          .css('div.mntl-recipe-details__content div.mntl-recipe-details__item div.mntl-recipe-details__label')
          .map { |e| e.text.parameterize.underscore }
          .zip(
            document
            .css('div.mntl-recipe-details__content div.mntl-recipe-details__item div.mntl-recipe-details__value')
            .map { |e| e.text.strip }
          ).to_h
      end
    end
  end
end
