require 'open3'

module Recipes
  class Import
    class RecipeScrapers < Base
      def initialize(document, source = nil)
        super

        @recipe_json ||= find_recipe_json
      end

      def recipe_name
        recipe_json['title']
      end

      def recipe_image_src
        return if recipe_json['image'].blank?

        image_uri = URI(recipe_json['image'])

        return unless image_uri.is_a?(URI::HTTP) || image_uri.is_a?(URI::HTTPS)

        image_uri.to_s
      end

      def recipe_yield
        recipe_json['yields']
      end

      def recipe_prep_time
        recipe_json['prep_time']
      end

      def recipe_cook_time
        recipe_json['cook_time']
      end

      def recipe_total_time
        recipe_json['total_time']
      end

      def recipe_category_names
        recipe_json['category']
          .split(',')
          .map { |name| name.strip.titleize }
          .compact_blank
      end

      def recipe_description
        recipe_json['description']
      end

      def recipe_ingredients
        recipe_json['ingredient_groups']
          .reduce('') do |text, group|
            text << "#{group['name'].upcase}\n" if group['purpose'].present?
            text << group['ingredients'].join("\n")
            text << "\n\n"
          end
      end

      def recipe_directions
        recipe_json['instructions_list'].join("\n\n")
      end

      private

      attr_reader :recipe_json

      def find_recipe_json
        scrape_path = Rails.root.join('bin/scrape')
        stdout, stderr, status = Open3.capture3(
          scrape_path.to_s,
          source.to_s,
          stdin_data: document.to_html
        )

        raise NotFoundError, "Recipe scrape failed: #{stderr.strip.presence || 'unknown error'}" unless status.success?

        JSON.parse(stdout)
      rescue JSON::ParserError
        raise NotFoundError, 'Recipe scrape returned invalid JSON'
      end

      class NotFoundError < StandardError; end
    end
  end
end
