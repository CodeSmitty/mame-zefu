# frozen_string_literal: true

require 'anthropic'
require 'json'
require 'timeout'

module Recipes
  class Extraction
    class Anthropic # rubocop:disable Metrics/ClassLength
      MODEL_NAME = 'claude-haiku-4-5'
      DEFAULT_TIMEOUT_SECONDS = 90
      EXTRACTABLE_FIELDS = %w[
        name
        yield
        prep_time
        cook_time
        total_time
        description
        ingredients
        directions
        category_names
      ].freeze
      IMAGE_PROMPT = <<~PROMPT
        Please print the recipe information extracted from this image.
        Do not include information that is not present in the image.
        For example, if there is no total time listed, do not calculate one from the prep time and cook time;
        if there are no intentional categories listed or description provided, don't invent them.
        If you cannot extract a particular field, return an empty string or empty list for that field.
        If you encounter handwriting that appears to have typos or is not perfectly legible,
        do your best to infer the intended text but do not invent information that is not present in the image.
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

      def initialize(image_file:)
        @image_file = image_file
      end

      def recipe
        response = with_timeout do
          client.messages.create(message_params)
        end
        Rails.logger.info("Received image extraction response: #{response.inspect}")
        parse_output(response)
      rescue ::Anthropic::Errors::APIError => e
        raise Error, "Image extraction failed: #{e.message}"
      rescue Timeout::Error
        raise Error, 'Image extraction timed out.'
      end

      private

      attr_reader :image_file

      def with_timeout(&)
        Timeout.timeout(timeout_seconds, &)
      end

      def timeout_seconds
        ENV.fetch('RECIPE_EXTRACTION_TIMEOUT_SECONDS', DEFAULT_TIMEOUT_SECONDS.to_s).to_i
      end

      def client
        @client ||= ::Anthropic::Client.new(timeout: timeout_seconds)
      end

      def model_name
        ENV.fetch('RECIPE_EXTRACTION_MODEL', MODEL_NAME)
      end

      def message_params # rubocop:disable Metrics/MethodLength
        {
          model: model_name,
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
        @image_source ||= Image.new(image_file:).source
      end

      def parse_output(response)
        tool_use_block = find_tool_use_block(response)

        raise Error, 'No extraction tool output was returned by the model.' unless tool_use_block

        normalize_extracted_payload(parsed_tool_input(tool_use_block.input))
      rescue JSON::ParserError => e
        raise Error, "Image extraction returned invalid JSON: #{e.message}"
      end

      def normalize_extracted_payload(payload)
        payload = payload.to_h.deep_stringify_keys
        payload = payload.slice(*EXTRACTABLE_FIELDS)
        payload['ingredients'] = normalize_array(payload['ingredients'])
        payload['directions'] = normalize_array(payload['directions'])
        payload['category_names'] = normalize_array(payload['category_names'])

        payload
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
