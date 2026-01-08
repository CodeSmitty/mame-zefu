module Recipes
  class Import
    class SimplyRecipes < Base
      def recipe_name
        document
          .css('h2.recipe-block__header')
          .text
      end

      def recipe_image_src
        document
          .css('div.primary-image__media > div >img')
          .first
          &.attr('src')
      end

      def recipe_yield
        document
          .css('div.recipe-serving span.meta-text__data')
          .text
      end

      def recipe_prep_time
        document
          .css('div.prep-time span.meta-text__data')
          .text
      end

      def recipe_cook_time
        document
          .css('div.cook-time span.meta-text__data')
          .text
      end

      def recipe_total_time
        document
          .css('div.total-time span.meta-text__data')
          .text
      end

      def recipe_ingredients
        document
          .css('ul.structured-ingredients__list li.structured-ingredients__list-item')
          .map { |li| li.text.strip }
          .join("\n")
      end

      def recipe_directions
        document
          .css('div.structured-project__steps li')
          .map do |li|
            heading = li.css('span.mntl-sc-block-subheading__text').text.strip.upcase
            body = li.xpath('./p').map { |p| p.text.strip }.join("\n\n")
            "#{heading}\n#{body}"
          end
          .join("\n\n")
      end
    end
  end
end
