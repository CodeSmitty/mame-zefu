module Recipes
  class Import
    require 'net/http'
    require 'nokogiri'
    require 'uri'

    def self.from_url(url)
      new(uri: URI(url)).recipe
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
      @recipe_class ||=
        case uri.host
        when 'www.tasteofhome.com'
          TasteOfHome
        when 'www.delish.com'
          Delish
        else
          raise UnknownHostError
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
