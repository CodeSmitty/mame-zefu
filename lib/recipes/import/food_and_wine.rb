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

      def recipe_ingredients # rubocop:disable Metrics
        document
          .css('div.mntl-structured-ingredients')
          .children
          .reduce('') do |text, node|
            next text unless node.element?

            if node.name == 'ul'
              text << node.children.map { |e| e.text.strip }.compact_blank.join("\n")
            elsif node.name == 'p' && node.text.present?
              text << "\n\n" if text.present?

              text << "#{node.text.upcase}\n"
            end

            text
          end
      end

      def recipe_directions # rubocop:disable Metrics
        document
          .css('div.recipe__steps-content')
          .children
          .reduce('') do |text, node|
            next text unless node.element?

            if node.name == 'ol'
              text << node.children.map { |e| e.text.strip }.compact_blank.join("\n\n")
            elsif node.name == 'h3' && node.text.present?
              text << "\n\n" if text.present?

              text << "#{node.text.strip.upcase}\n"
            end

            text
          end
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
