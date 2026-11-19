# frozen_string_literal: true

module Recipes
  class Import
    require 'uri'

    RECIPE_CLASSES = {
      'www.gordonramsay.com' => GordonRamsay
    }.freeze
    def recipe
      klass = recipe_class
      imported_recipe = import_recipe(klass)
      return imported_recipe if imported_recipe

      if klass == RecipeScrapers
        Rails.logger.warn('RecipeScrapers did not produce recipe details, trying JSON-LD')
        imported_recipe = import_recipe(JsonSchema)
        return imported_recipe if imported_recipe
      end

      raise NotFoundError, 'No recipe details found on the page'
    end

    def self.from_url(url)
      new(uri: URI(url))
    end

    class NotFoundError < StandardError; end
    class FetchError < StandardError; end

    private

    attr_reader :uri

    def import_recipe(klass)
      importer = klass.new(klass == RecipeScrapers ? nil : document, uri)
      imported_recipe = importer.recipe
      imported_recipe if imported_recipe_fields_present?(imported_recipe)
    rescue RecipeScrapers::NotFoundError => e
      raise unless klass == RecipeScrapers

      Rails.logger.warn("RecipeScrapers import failed: #{e.message}")
      nil
    end

    def imported_recipe_fields_present?(recipe)
      Base::IMPORT_FIELDS
        .excluding('source', 'is_favorite')
        .any? { |field| recipe.public_send(field).present? }
    end

    def initialize(uri:)
      @uri = uri
    end

    def recipe_class
      return RECIPE_CLASSES[uri.host] if RECIPE_CLASSES.key?(uri.host)
      return RecipeScrapers if RecipeScrapers.supported_host?(uri.host)

      JsonSchema
    end

    def document
      @document ||= PageFetcher.new(uri).document
    end
  end
end
