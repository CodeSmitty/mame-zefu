# frozen_string_literal: true

require 'anthropic'
require 'json'

module Recipes
  class Extraction
    class Anthropic # rubocop:disable Metrics/ClassLength
      MODEL_NAME = 'claude-haiku-4-5'
      TIMEOUT_SECONDS = 90
      IMAGE_PROMPT = <<~PROMPT
        Extract recipe data from this image and provide values only for this tool schema.

        Rules:
        1) Return only information visible in the image. Do not calculate or invent values.
        2) Preserve wording as written, except trim leading/trailing whitespace.
        3) If a field is missing, return an empty string (for string fields) or empty array (for array fields).
        4) For array fields (ingredients, directions, category_names):
           - return one clean item per entry
           - remove bullets/numbers from item starts
           - do not include blank items
        5) Do not include extra fields outside the schema.
        6) If handwriting/OCR is uncertain, you may infer individual words, phrases or values but do not invent information.
      PROMPT
      IMAGE_TOOL = {
        name: 'recipe_extractor',
        description: 'Extracts recipe information from an image containing a recipe',
        input_schema: {
          type: 'object',
          properties: {
            name: {
              type: 'string',
              description: 'The name of the recipe'
            },
            yield: {
              type: 'string',
              description: 'The yield of the recipe (e.g., number of servings)'
            },
            prep_time: {
              type: 'string',
              description: 'The preparation time required for the recipe'
            },
            cook_time: {
              type: 'string',
              description: 'The cooking time required for the recipe'
            },
            total_time: {
              type: 'string',
              description: 'The total time required for the recipe'
            },
            category_names: {
              type: 'array',
              items: { type: 'string' },
              description: 'A list of category names for the recipe'
            },
            description: {
              type: 'string',
              description: 'A brief description of the recipe'
            },
            ingredients: {
              type: 'array',
              items: { type: 'string' },
              description: 'A list of ingredients required for the recipe'
            },
            directions: {
              type: 'array',
              items: { type: 'string' },
              description: 'A list of step-by-step directions for preparing the recipe'
            }
          },
          required: %w[name ingredients directions]
        }
      }.freeze
      SCHEMA_PROPERTIES = IMAGE_TOOL.fetch(:input_schema).fetch(:properties).deep_stringify_keys.freeze

      def initialize(image_file:, media_type:)
        @image_file = image_file
        @media_type = media_type
      end

      def recipe
        response = client.messages.create(message_params)
        parse_output(response)
      rescue ::Anthropic::Errors::APIError => e
        raise Error, "Image extraction failed: #{e.message}"
      end

      private

      attr_reader :image_file, :media_type

      def client
        @client ||= ::Anthropic::Client.new(timeout: TIMEOUT_SECONDS)
      end

      def message_params # rubocop:disable Metrics/MethodLength
        {
          model: MODEL_NAME,
          max_tokens: 4096,
          messages: [
            {
              role: 'user',
              content: message_content
            }
          ],
          tools: [IMAGE_TOOL]
        }
      end

      def message_content
        [
          {
            type: 'image',
            source: image_source
          },
          {
            type: 'text',
            text: IMAGE_PROMPT
          }
        ]
      end

      def image_source
        @image_source ||= Image.new(image_file:, media_type:).source
      end

      def parse_output(response)
        tool_use_block = find_tool_use_block(response)

        raise Error, 'No extraction tool output was returned by the model.' unless tool_use_block

        tool_use_block
          .input
          .then { parsed_tool_input(_1) }
          .then { normalize_extracted_payload(_1) }
      rescue JSON::ParserError => e
        raise Error, "Image extraction returned invalid JSON: #{e.message}"
      end

      def normalize_extracted_payload(payload)
        source = payload.to_h.deep_stringify_keys

        SCHEMA_PROPERTIES.each_with_object({}) do |(key, schema), acc|
          case schema['type']
          when 'string'
            acc[key] = source.fetch(key, '').to_s.strip
          when 'array'
            acc[key] = normalize_array(source.fetch(key, []))
          end
        end
      end

      def find_tool_use_block(response)
        Array(response.content).find do |block|
          block.respond_to?(:type) && block.type.to_s == 'tool_use' &&
            block.respond_to?(:name) && block.name.to_s == IMAGE_TOOL[:name]
        end
      end

      def parsed_tool_input(input)
        return input if input.is_a?(Hash)

        JSON.parse(input.to_json)
      end

      def normalize_array(value)
        Array(value).map(&:to_s).map(&:strip).compact_blank
      end

      class Error < Recipes::Extraction::Error; end
    end
  end
end
