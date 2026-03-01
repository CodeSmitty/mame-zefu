# frozen_string_literal: true

module Recipes
  class Extraction
    delegate :recipe, to: :extractor

    def self.from_file(image_file)
      new(image_file:).recipe
    end

    private

    attr_reader :image_file

    def initialize(image_file:)
      @image_file = image_file
      # validate_image!
    end

    # def validate_image!
    #   content_type = image_file.content_type.to_s
    #   return if content_type.start_with?('image/')

    #   raise Error, 'Unsupported file type. Image is required.'
    # end

    def extractor
      @extractor ||= Anthropic.new(image_file:)
    end

    class Error < StandardError; end
  end
end
