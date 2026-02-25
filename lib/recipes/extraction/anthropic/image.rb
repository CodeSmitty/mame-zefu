# frozen_string_literal: true

require 'base64'
require 'mini_magick'

module Recipes
  class Extraction
    class Anthropic
      class Image # rubocop:disable Metrics/ClassLength
        MAX_BASE64_FIELD_BYTES = 5 * 1024 * 1024
        MAX_IMAGE_BYTES = (MAX_BASE64_FIELD_BYTES * 3) / 4
        MAX_RESIZE_ATTEMPTS = 6
        QUALITY_MIN = 45
        QUALITY_MAX = 95
        QUALITY_FLOOR = 35
        RESIZE_SHRINK_FACTOR = 0.85
        PAYLOAD_LIMIT_ERROR =
          'Image could not be reduced under the API payload limit. Try a smaller crop or lower-resolution source image.'
        IMAGEMAGICK_MISSING_ERROR =
          'Image preprocessing requires ImageMagick CLI tools. Install imagemagick or upload a smaller image.'

        def initialize(image:)
          @image = image
        end

        def source
          image_bytes, media_type = call

          {
            type: 'base64',
            media_type:,
            data: Base64.strict_encode64(image_bytes)
          }
        end

        private

        def call # rubocop:disable Metrics/MethodLength
          ensure_imagemagick_available!

          normalized = normalized_image(source_image_bytes)
          normalized_bytes = normalized.to_blob
          normalized_media_type = normalized_media_type_for(normalized)

          if payload_within_limit?(normalized_bytes)
            log_normalized_fit(bytes: normalized_bytes.bytesize, media_type: normalized_media_type)
            return [normalized_bytes, normalized_media_type]
          end

          [downsampled_jpeg_bytes(normalized), 'image/jpeg']
        rescue MiniMagick::Error => e
          raise Error, preprocessing_error_message(e)
        ensure
          normalized&.destroy!
        end

        attr_reader :image

        def ensure_imagemagick_available!
          required_tools = %w[mogrify identify convert]
          return if required_tools.all? { |tool| MiniMagick::Utilities.which(tool).present? }

          raise Error, IMAGEMAGICK_MISSING_ERROR
        end

        def source_image_bytes
          tempfile = image.tempfile
          tempfile.rewind
          tempfile.read.to_s.b
        ensure
          tempfile.rewind
        end

        def payload_within_limit?(bytes)
          bytes.bytesize <= MAX_IMAGE_BYTES && base64_length(bytes) <= MAX_BASE64_FIELD_BYTES
        end

        def base64_length(bytes)
          ((bytes.bytesize + 2) / 3) * 4
        end

        def downsampled_jpeg_bytes(image) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          candidate_width, candidate_height = initial_resize_target(image)
          attempts = 0

          MAX_RESIZE_ATTEMPTS.times do
            attempts += 1
            candidate = image.clone
            resize_to(candidate, width: candidate_width, height: candidate_height)

            jpeg_bytes, quality = best_fit_jpeg_bytes(candidate)
            if jpeg_bytes
              log_downsample_success(
                attempts:,
                width: candidate_width,
                height: candidate_height,
                quality:,
                bytes: jpeg_bytes.bytesize
              )
              return jpeg_bytes
            end
          ensure
            candidate&.destroy!
            candidate_width = [1, (candidate_width * RESIZE_SHRINK_FACTOR).to_i].max
            candidate_height = [1, (candidate_height * RESIZE_SHRINK_FACTOR).to_i].max
          end

          log_downsample_failure(attempts:)
          raise Error, PAYLOAD_LIMIT_ERROR
        end

        def initial_resize_target(image)
          raw_bytes = image.to_blob.bytesize
          return [image.width, image.height] if raw_bytes <= MAX_IMAGE_BYTES

          target_ratio = Math.sqrt(MAX_IMAGE_BYTES.to_f / raw_bytes)
          resize_ratio = target_ratio.clamp(0.1, 1.0)

          [
            [1, (image.width * resize_ratio).to_i].max,
            [1, (image.height * resize_ratio).to_i].max
          ]
        end

        def best_fit_jpeg_bytes(image) # rubocop:disable Metrics/MethodLength
          low = QUALITY_MIN
          high = QUALITY_MAX
          best = nil
          best_quality = nil

          while low <= high
            quality = (low + high) / 2
            bytes = encode_jpeg(image, quality:)

            if payload_within_limit?(bytes)
              best = bytes
              best_quality = quality
              low = quality + 1
            else
              high = quality - 1
            end
          end

          return [best, best_quality] if best

          fallback = encode_jpeg(image, quality: QUALITY_FLOOR)
          return [fallback, QUALITY_FLOOR] if payload_within_limit?(fallback)

          [nil, nil]
        end

        def normalized_image(source_bytes)
          image = MiniMagick::Image.read(source_bytes)
          image.auto_orient
          image.combine_options do |builder|
            builder.colorspace 'sRGB'
            builder.background 'white'
            builder.alpha 'remove'
            builder.flatten
            builder.strip
          end
          image
        end

        def normalized_media_type_for(normalized) # rubocop:disable Metrics/MethodLength
          case normalized.type.to_s.downcase
          when 'jpeg', 'jpg'
            'image/jpeg'
          when 'png'
            'image/png'
          when 'webp'
            'image/webp'
          when 'gif'
            'image/gif'
          else
            image.content_type.presence || 'image/jpeg'
          end
        end

        def resize_to(image, width:, height:)
          return if image.width == width && image.height == height

          image.resize("#{width}x#{height}")
        end

        def encode_jpeg(image, quality:)
          image.format('jpg')
          image.combine_options do |builder|
            builder.quality quality.to_s
            builder.strip
          end
          image.to_blob
        end

        def preprocessing_error_message(error)
          return IMAGEMAGICK_MISSING_ERROR if error.message.to_s.include?('executable not found')

          "Image preprocessing failed: #{error.message}"
        end

        def log_normalized_fit(bytes:, media_type:)
          logger.info("Recipe extraction image: normalized bytes=#{bytes} media_type=#{media_type} (no downsample)")
        end

        def log_downsample_success(attempts:, width:, height:, quality:, bytes:)
          logger.info(
            "Recipe extraction image: downsampled attempts=#{attempts} " \
            "dimensions=#{width}x#{height} quality=#{quality} bytes=#{bytes}"
          )
        end

        def log_downsample_failure(attempts:)
          logger.warn("Recipe extraction image: failed to fit payload after #{attempts} attempts")
        end

        def logger
          Rails.logger
        end

        class Error < Recipes::Extraction::Anthropic::Error; end
      end
    end
  end
end
