# frozen_string_literal: true

require 'base64'
require 'mini_magick'

module Recipes
  class Extraction
    class Anthropic
      class Image # rubocop:disable Metrics/ClassLength
        MAX_BASE64_BYTES = 5 * 1024 * 1024
        MAX_RESIZE_ATTEMPTS = 6
        QUALITY_MIN = 45
        QUALITY_MAX = 95
        QUALITY_FLOOR = 35
        RESIZE_FACTOR = 0.85
        PAYLOAD_LIMIT_ERROR = 'Image could not be reduced under the API payload limit.'
        IMAGEMAGICK_MISSING_ERROR = 'Image preprocessing requires ImageMagick CLI tools.'
        LOG_PREFIX = 'Recipe extraction image:'

        def initialize(image:)
          ensure_imagemagick_available!

          @media_type = image.content_type.presence || 'image/jpeg'
          @image_bytes = bytes_for(image)
        end

        def source
          process_image

          {
            type: 'base64',
            media_type: media_type,
            data: Base64.strict_encode64(image_bytes)
          }
        end

        private

        attr_reader :image_bytes, :media_type

        def process_image
          image = normalized_image
          @image_bytes = image.to_blob
          @media_type = media_type_for(image)

          log_normalized_fit and return if payload_within_limit?(image_bytes)

          @image_bytes = downsampled_jpeg_bytes(image)
          @media_type = 'image/jpeg'
        rescue MiniMagick::Error => e
          raise Error, preprocessing_error_message(e)
        ensure
          image&.destroy!
        end

        def ensure_imagemagick_available!
          required_tools = %w[mogrify identify convert]
          return if required_tools.all? { |tool| MiniMagick::Utilities.which(tool).present? }

          raise Error, IMAGEMAGICK_MISSING_ERROR
        end

        def bytes_for(image)
          tempfile = image.tempfile
          tempfile.rewind
          tempfile.read.to_s.b
        ensure
          tempfile.rewind
        end

        def normalized_image
          image = MiniMagick::Image.read(image_bytes)
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

        def media_type_for(image)
          case image.type.to_s.downcase
          when 'png'
            'image/png'
          when 'webp'
            'image/webp'
          when 'gif'
            'image/gif'
          else
            'image/jpeg'
          end
        end

        def payload_within_limit?(bytes)
          base64_length(bytes) <= MAX_BASE64_BYTES
        end

        def base64_length(bytes)
          ((bytes.bytesize + 2) / 3) * 4
        end

        # Finds a payload-fitting JPEG using a targeted search strategy instead of
        # exhaustively trying every scale/quality pair.
        #
        # Algorithm:
        # 1) Compute an initial resize target from the ratio between current bytes
        #    and the configured payload ceiling (square-root area estimate).
        # 2) For each resize attempt, resize once to the candidate dimensions.
        # 3) Run a binary search over JPEG quality to find the highest quality that
        #    still fits within the payload limit at those dimensions.
        # 4) If no quality fits, shrink dimensions by RESIZE_FACTOR and retry.
        #
        # This converges faster than a grid search while preserving as much visual
        # fidelity as possible for OCR and model extraction quality.
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
            candidate_width = [1, (candidate_width * RESIZE_FACTOR).to_i].max
            candidate_height = [1, (candidate_height * RESIZE_FACTOR).to_i].max
          end

          log_downsample_failure(attempts:)
          raise Error, PAYLOAD_LIMIT_ERROR
        end

        def initial_resize_target(image)
          raw_bitesize = image.to_blob.bytesize
          max_bytesize = (MAX_BASE64_BYTES * 3) / 4

          target_ratio = Math.sqrt(max_bytesize.to_f / raw_bitesize)
          resize_ratio = target_ratio.clamp(0.1, 1.0)

          [
            [1, (image.width * resize_ratio).to_i].max,
            [1, (image.height * resize_ratio).to_i].max
          ]
        end

        def resize_to(image, width:, height:)
          return if image.width == width && image.height == height

          image.resize("#{width}x#{height}")
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

        def log_normalized_fit
          logger.info("#{LOG_PREFIX} normalized bytes=#{image_bytes.bytesize} media_type=#{media_type} (no downsample)")
        end

        def log_downsample_success(attempts:, width:, height:, quality:, bytes:)
          logger.info(
            "#{LOG_PREFIX} downsampled attempts=#{attempts} " \
            "dimensions=#{width}x#{height} quality=#{quality} bytes=#{bytes}"
          )
        end

        def log_downsample_failure(attempts:)
          logger.warn("#{LOG_PREFIX} failed to fit payload after #{attempts} attempts")
        end

        def logger
          Rails.logger
        end

        class Error < Recipes::Extraction::Anthropic::Error; end
      end
    end
  end
end
