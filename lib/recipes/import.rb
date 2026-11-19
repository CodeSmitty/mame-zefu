# frozen_string_literal: true

module Recipes
  class Import
    require 'net/http'
    require 'nokogiri'
    require 'uri'

    RECIPE_CLASSES = {
      'www.gordonramsay.com' => GordonRamsay
    }.freeze
    USER_AGENT = 'Mozilla/5.0 (compatible; MameZefu/1.0)'
    MAX_REDIRECTS = 5

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

    def self.from_url(url, force_json_schema: false)
      new(uri: URI(url), force_json_schema:)
    end

    class NotFoundError < StandardError; end
    class FetchError < StandardError; end

    private

    attr_reader :uri, :force_json_schema

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

    def initialize(uri:, force_json_schema: false)
      @uri = uri
      @force_json_schema = force_json_schema
    end

    def recipe_class
      return JsonSchema if force_json_schema

      return RECIPE_CLASSES[uri.host] if RECIPE_CLASSES.key?(uri.host)
      return RecipeScrapers if RecipeScrapers.supported_host?(uri.host)

      JsonSchema
    end

    def document
      @document ||= Nokogiri::HTML(body)
    end

    def body
      @body ||= fetch_body(uri)
    end

    def fetch_body(url, redirects = MAX_REDIRECTS)
      response = Net::HTTP.get_response(url, 'User-Agent' => USER_AGENT)
      return response.body if response.is_a?(Net::HTTPSuccess)

      if response.is_a?(Net::HTTPRedirection) && response['location'].present? && redirects.positive?
        return fetch_body(URI.join(url, response['location']), redirects - 1)
      end

      raise FetchError, "Recipe page request failed: HTTP #{response.code}"
    end
  end
end
