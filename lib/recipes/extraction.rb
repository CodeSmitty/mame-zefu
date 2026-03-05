# frozen_string_literal: true

module Recipes
  class Extraction
    VALID_TYPES = ['image/jpeg', 'image/png', 'image/webp'].freeze
    MAX_IMAGE_SIZE = Recipe::MAX_IMAGE_SIZE

    delegate :recipe, to: :extractor

    def self.from_file(image_file)
      new(image_file:).recipe
    end

    private

    attr_reader :image_file, :media_type

    def initialize(image_file:)
      @image_file = image_file
      @media_type = Marcel::MimeType.for(Pathname.new(image_file), name: File.basename(image_file)).to_s
      validate_image_file!
    end

    def extractor
      @extractor ||= Anthropic.new(image_file:, media_type:)
    end

    def validate_image_file!
      unless valid_image_size?
        raise Error, "Image is too large. Maximum allowed size is #{MAX_IMAGE_SIZE / 1.megabyte} MB."
      end

      raise Error, 'Unsupported file type. Image is required.' unless valid_image_type?
    end

    def valid_image_size?
      File.size(image_file) <= MAX_IMAGE_SIZE
    end

    def valid_image_type?
      VALID_TYPES.include?(@media_type)
    end

    class Error < StandardError; end
  end
end
