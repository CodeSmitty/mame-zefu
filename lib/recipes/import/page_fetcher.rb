# frozen_string_literal: true

require 'net/http'
require 'nokogiri'
require 'uri'

module Recipes
  class Import
    class PageFetcher
      USER_AGENT = 'Mozilla/5.0 (compatible; MameZefu/1.0)'
      MAX_REDIRECTS = 5

      def initialize(uri)
        @uri = uri
      end

      def document
        @document ||= Nokogiri::HTML(fetch_body(uri))
      end

      private

      attr_reader :uri

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
end
