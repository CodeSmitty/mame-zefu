module Recipes
  class Import
    class RecipeKeeper < Base
      def recipe_name
        document
          .css('[itemprop="name"]')
          .text
      end

      def recipe_yield
        document
          .css('[itemprop="recipeYield"]')
          .text
      end

      def recipe_prep_time
        document
          .css('[itemprop="prepTime"]')
          .xpath('preceding-sibling::span')
          .text
      end

      def recipe_cook_time
        document
          .css('[itemprop="cookTime"]')
          .xpath('preceding-sibling::span')
          .text
      end

      def recipe_total_time
        document
          .css('[itemprop="totalTime"]')
          .xpath('preceding-sibling::span')
          .text
      end

      def recipe_ingredients
        document
          .css('[itemprop="recipeIngredients"]')
          .text
          .then { |text| trim_whitespace(text) }
      end

      def recipe_directions
        document
          .css('[itemprop="recipeDirections"]')
          .text
          .then { |text| trim_whitespace(text) }
      end

      def recipe_notes
        document
          .css('[itemprop="recipeNotes"]')
          .text
          .then { |text| trim_whitespace(text) }
      end

      def recipe_rating
        document
          .css('[itemprop="recipeRating"]')
          .attribute('content')
          .to_s
      end

      def recipe_is_favorite # rubocop:disable Naming/PredicateMethod
        document
          .css('[itemprop="recipeIsFavourite"]')
          .attribute('content')
          .to_s == 'True'
      end

      def recipe_category_names
        (recipe_courses + recipe_categories + recipe_collections).compact_blank
      end

      def recipe_source
        document
          .css('[itemprop="recipeSource"] a')
          .attribute('href')
          .to_s
      end

      def recipe_image_src
        document
          .css('[itemprop="photo0"]')
          .attribute('src')
          .to_s
      end

      private

      def recipe_courses
        document.css('[itemprop="recipeCourse"]').map { |elem| elem.text.presence || elem.attribute('content').to_s }
      end

      def recipe_categories
        document.css('[itemprop="recipeCategory"]').map { |elem| elem.attribute('content').to_s }
      end

      def recipe_collections
        document.css('[itemprop="recipeCollection"]').map { |elem| elem.attribute('content').to_s }
      end

      def trim_whitespace(text)
        text.gsub(/\A\s+|\s+\Z/, '').gsub(/^ +| +$/, '')
      end
    end
  end
end
