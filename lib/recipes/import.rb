# frozen_string_literal: true

module Recipes
  class Import
    require 'net/http'
    require 'nokogiri'
    require 'uri'

    delegate :recipe, to: :recipe_class_instance

    RECIPE_CLASSES = {
      'www.gordonramsay.com' => GordonRamsay
    }.freeze

    def self.from_url(url, force_json_schema: false)
      new(uri: URI(url), force_json_schema:)
    end

    private

    attr_reader :uri, :force_json_schema

    def initialize(uri:, force_json_schema: false)
      @uri = uri
      @force_json_schema = force_json_schema
    end

    def recipe_class
      return JsonSchema if force_json_schema

      RECIPE_CLASSES.fetch(uri.host, JsonSchema)
    end

    def recipe_class_instance
      @recipe_class_instance ||= recipe_class.new(document, uri)
    end

    def document
      @document ||= Nokogiri::HTML(body)
    end

    def body
      @body ||= Net::HTTP.get(uri)
    end
  end
end
