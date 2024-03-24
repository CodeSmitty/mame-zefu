module Recipes
  class Import
    require 'net/http'
    require 'nokogiri'
    require 'uri'

    RECIPE_CLASSES = {
      'www.tasteofhome.com' => TasteOfHome,
      'www.delish.com' => Delish,
      'www.allrecipes.com' => AllRecipes,
      'www.gordonramsay.com' => GordonRamsay,
      'www.simplyrecipes.com' => SimplyRecipes,
      'www.foodandwine.com' => FoodAndWine,
      'www.foodnetwork.com' => FoodNetwork
    }.freeze

    def self.from_url(url)
      new(uri: URI(url)).recipe.tap do |recipe|
        recipe.source = url
      end
    end

    def recipe
      recipe_class.new(document).recipe
    end

    private

    attr_reader :uri

    def initialize(uri:)
      @uri = uri
    end

    def recipe_class
      RECIPE_CLASSES.fetch(uri.host) do
        raise UnknownHostError, "Unknown host: #{uri.host}"
      end
    end

    def document
      @document ||= Nokogiri::HTML(body)
    end

    def body
      @body ||= Net::HTTP.get(uri)
    end

    class UnknownHostError < StandardError; end
  end
end
