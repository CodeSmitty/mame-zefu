# frozen_string_literal: true

module Recipes
  class Extraction
    delegate :recipe, to: :extractor

    def self.from_upload(image)
      new(image:).recipe
    end

    private

    attr_reader :image

    def initialize(image:)
      @image = image
      validate_image!
    end

    def validate_image!
      content_type = image.content_type.to_s
      return if content_type.start_with?('image/')

      raise Error, 'Unsupported file type. Image is required.'
    end

    def extractor
      @extractor ||= Anthropic.new(image:)
    end

    class Error < StandardError; end
  end
end
