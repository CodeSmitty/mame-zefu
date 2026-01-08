module Recipes
  class Archive
    class RecipeKeeper < Archive
      def generate
        raise NotImplementedError, 'Exporting to Recipe Keeper format is not supported'
      end

      private

      def recipe_filename
        'recipes.html'
      end

      def extract_recipes(contents)
        document = Nokogiri::HTML(contents)
        document.css('.recipe-details')
      end

      def load_recipe(recipe_doc)
        Recipes::Import::RecipeKeeper.new(recipe_doc).recipe
      end
    end
  end
end
