module Recipes
  class Import
    class GordonRamsay < Base
      def recipe_name
        document
          .css('div.hero-title-recipe h2')
          .text
      end

      def recipe_image_url
        document
          .css('div.hero-image-recipe > div:first-child > img')
          .first
          &.attr('src')
          &.then { |src| src.insert(0, 'https://gordonramsay.com') }
      end

      def recipe_yield
        document
          .css('article.recipe-instructions')
          .xpath("//p[starts-with(text(),'Serves')]")
          .text
      end

      def recipe_ingredients # rubocop:disable Metrics
        document
          .css('aside.recipe-ingredients')
          .children
          .reduce('') do |text, node|
            next text unless node.element?

            if node.name == 'ul'
              text << node.children.map(&:text).join
            elsif node.name == 'p' && node.text.present?
              text << "\n" if text.present?

              text << "#{node.text.upcase}\n"
            end

            text
          end
      end

      def recipe_directions
        document
          .css('article.recipe-instructions ol li')
          .map { |e| e.text.strip }
          .join("\n\n")
      end
    end
  end
end
