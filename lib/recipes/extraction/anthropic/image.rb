# frozen_string_literal: true

require 'base64'
require 'mini_magick'

module Recipes
  class Extraction
    class Anthropic
      class Image # rubocop:disable Metrics/ClassLength
        MAX_BASE64_BYTES = 2 * 1024 * 1024
        MAX_RESIZE_ATTEMPTS = 3
        QUALITY_CANDIDATES = [95, 92, 90, 88, 85].freeze
        RESIZE_FACTOR = 0.85
        PAYLOAD_LIMIT_ERROR = 'Image could not be reduced under the payload limit.'
        IMAGEMAGICK_MISSING_ERROR = 'Image preprocessing requires ImageMagick CLI tools.'

        def initialize(image_file:, media_type:)
          ensure_imagemagick_available!

          @image = MiniMagick::Image.open(image_file)
          @media_type = media_type
        end

        def source
          process_image

          {
            type: 'base64',
            media_type:,
            data: Base64.strict_encode64(image.to_blob)
          }
        end

        private

        attr_reader :image, :media_type

        def process_image
          normalize_image

          return if within_size_limit?(image)

          downsample_image
        rescue MiniMagick::Error => e
          raise Error, "Image preprocessing failed: #{e.message}"
        end

        def ensure_imagemagick_available!
          required_tools = %w[mogrify identify convert]
          return if required_tools.all? { |tool| MiniMagick::Utilities.which(tool).present? }

          raise Error, IMAGEMAGICK_MISSING_ERROR
        end

        def normalize_image
          image.auto_orient
          image.combine_options do |builder|
            builder.colorspace 'sRGB'
            builder.background 'white'
            builder.alpha 'remove'
            builder.flatten
            builder.strip
          end
        end

        def within_size_limit?(image)
          base64_length(image.to_blob) <= MAX_BASE64_BYTES
        end

        def base64_length(bytes)
          ((bytes.bytesize + 2) / 3) * 4
        end

        def downsample_image # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          candidate_width, candidate_height = initial_resize_target

          jpeg = nil
          MAX_RESIZE_ATTEMPTS.times do |i|
            candidate = open_copy(image)
            candidate.resize("#{candidate_width}x#{candidate_height}")

            jpeg, quality = best_fit_jpeg(candidate)

            if jpeg
              log_downsample(resize_count: i + 1, jpeg:, quality:)
              break
            end

            candidate_width = [1, (candidate_width * RESIZE_FACTOR).to_i].max
            candidate_height = [1, (candidate_height * RESIZE_FACTOR).to_i].max
          ensure
            candidate&.destroy! unless jpeg.equal?(candidate)
          end

          @image = jpeg or raise Error, PAYLOAD_LIMIT_ERROR
          @media_type = 'image/jpeg'
        end

        def open_copy(image)
          MiniMagick::Image.open(image.path)
        end

        def initial_resize_target
          raw_bytesize = image.to_blob.bytesize
          max_bytesize = (MAX_BASE64_BYTES * 3) / 4

          target_ratio = Math.sqrt(max_bytesize.to_f / raw_bytesize)
          resize_ratio = target_ratio.clamp(0.1, 1.0)

          [
            resize_dimension(image.width, resize_ratio),
            resize_dimension(image.height, resize_ratio)
          ]
        end

        def resize_dimension(length, ratio)
          [1, (length * ratio).to_i].max
        end

        def best_fit_jpeg(image)
          jpeg = open_copy(image)
          jpeg.format('jpg') unless jpeg.type.to_s.casecmp('JPEG').zero?

          QUALITY_CANDIDATES.each do |quality|
            downsampled = downsample_jpeg(open_copy(jpeg), quality:)
            return [downsampled, quality] if within_size_limit?(downsampled)

            downsampled.destroy!
          end

          [nil, nil]
        ensure
          jpeg&.destroy!
        end

        def downsample_jpeg(image, quality:)
          image.combine_options do |builder|
            builder.quality quality.to_s
            builder.strip
          end
          image
        end

        def log_downsample(resize_count:, jpeg:, quality:)
          logger.info(
            'Image downsample: ' \
            "resize_count=#{resize_count} " \
            "input=#{image_dimensions(image)},#{image_size(image)} " \
            "output=#{image_dimensions(jpeg)},#{image_size(jpeg)},#{quality}%"
          )
        end

        def image_dimensions(image)
          "#{image.width}x#{image.height}"
        end

        def image_size(image)
          "#{(base64_length(image.to_blob).to_f / (1024 * 1024)).round(2)}MB"
        end

        def logger
          Rails.logger
        end

        class Error < Recipes::Extraction::Anthropic::Error; end
      end
    end
  end
end
