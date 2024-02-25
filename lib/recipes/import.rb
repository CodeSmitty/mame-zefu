module Recipes
  class Import
    require 'nokogiri'
    require 'open-uri'

    def self.from_url(url)
      new(Nokogiri::HTML(URI.open(url)))
    end

    def initialize(document)
      @document = document
    end

    def recipe
      Recipe.new.tap do |r|
        r.name = recipe_name
        r.yield = recipe_yield
        r.ingredients = recipe_ingredients
        r.directions = recipe_directions
      end
    end

    private

    attr_reader :document

    def recipe_name
      document
        .css('h1.recipe-title')
        .text
    end

    def recipe_yield
      document
        .css('div.makes p')
        .text
    end

    def recipe_ingredients
      document
        .css('div.recipe-ingredients ul.recipe-ingredients__list li')
        .map(&:text)
        .join("\n")
    end

    def recipe_directions
      document
        .css('div.recipe-directions ol.recipe-directions__list li.recipe-directions__item')
        .map { |li| li.css('span').text.strip }
        .join("\n\n")
    end
  end
end
