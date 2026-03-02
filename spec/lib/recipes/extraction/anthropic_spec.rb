# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Extraction::Anthropic do
  let(:service) { described_class.new(image_file: 'spec/fixtures/files/test.png', media_type: 'image/png') }
  let(:default_string_fields) do
    {
      'yield' => '',
      'prep_time' => '',
      'cook_time' => '',
      'total_time' => '',
      'description' => ''
    }
  end
  let(:image_source) { { type: 'base64', media_type: 'image/png', data: 'abc' } }
  let(:image_builder) { instance_double(Recipes::Extraction::Anthropic::Image, source: image_source) }
  let(:messages) { double('AnthropicMessages') } # rubocop:disable RSpec/VerifiedDoubles
  let(:client) { instance_double(Anthropic::Client, messages:) }

  before do
    allow(Recipes::Extraction::Anthropic::Image).to receive(:new).and_return(image_builder)
    allow(Anthropic::Client).to receive(:new).with(timeout: described_class::TIMEOUT_SECONDS).and_return(client)
  end

  describe '#recipe' do
    context 'when tool output is returned' do
      let(:expected_request) do
        hash_including(
          model: described_class::MODEL_NAME,
          max_tokens: 4096,
          tools: [described_class::IMAGE_TOOL]
        )
      end
      let(:input) do
        {
          name: 'Cake',
          ingredients: [' sugar '],
          directions: [' mix '],
          category_names: [' dessert ']
        }
      end
      let(:response) { tool_use_response(input) }

      before do
        allow(messages).to receive(:create).and_return(response)
      end

      it 'sends the expected model request' do
        service.recipe

        expect(messages).to have_received(:create).with(expected_request)
      end

      it 'normalizes name field' do
        expect(service.recipe['name']).to eq('Cake')
      end

      it 'fills missing string fields with empty strings' do
        expect(service.recipe).to include(default_string_fields)
      end

      it 'normalizes ingredients array' do
        expect(service.recipe['ingredients']).to eq(['sugar'])
      end

      it 'normalizes directions array' do
        expect(service.recipe['directions']).to eq(['mix'])
      end

      it 'normalizes category names array' do
        expect(service.recipe['category_names']).to eq(['dessert'])
      end
    end

    context 'when payload includes extra fields and noisy arrays' do
      let(:expected_fields) do
        {
          'name' => 'Cake',
          'ingredients' => ['sugar'],
          'directions' => %w[mix bake],
          'category_names' => %w[dessert 7]
        }
      end
      let(:input) do
        {
          name: 'Cake',
          ingredients: [' sugar ', nil, ''],
          directions: [' mix ', 'bake'],
          category_names: [' dessert ', 7, ''],
          extra_field: 'ignore-me'
        }
      end

      before do
        allow(messages).to receive(:create).and_return(tool_use_response(input))
      end

      it 'drops unknown fields' do
        expect(service.recipe).not_to have_key('extra_field')
      end

      it 'keeps normalized schema fields' do
        expect(service.recipe).to include(expected_fields)
      end

      it 'fills missing schema fields with defaults' do
        expect(service.recipe).to include(default_string_fields)
      end
    end

    it 'raises when no tool output is returned' do
      allow(messages).to receive(:create).and_return(Struct.new(:content).new([]))

      expect { service.recipe }.to raise_error(described_class::Error, /No extraction tool output/)
    end

    it 'raises when tool input cannot be parsed as JSON' do
      allow(messages).to receive(:create).and_return(tool_use_response(invalid_json_input))

      expect { service.recipe }.to raise_error(described_class::Error, /invalid JSON/)
    end

    it 'wraps API errors from Anthropic client' do
      api_error = Anthropic::Errors::APIError.new(url: 'https://api.anthropic.com', message: 'boom')
      allow(messages).to receive(:create).and_raise(api_error)

      expect { service.recipe }.to raise_error(described_class::Error, /Image extraction failed: boom/)
    end
  end

  describe 'private helpers' do
    it 'memoizes image source builder' do
      first = service.send(:image_source)
      second = service.send(:image_source)

      expect(first).to eq(image_source)
      expect(second).to eq(image_source)
      expect(Recipes::Extraction::Anthropic::Image).to have_received(:new).once
    end
  end

  def tool_use_response(input)
    block = Struct.new(:type, :name, :input).new('tool_use', 'recipe_extractor', input)
    Struct.new(:content).new([block])
  end

  def invalid_json_input
    Class.new do
      def to_json(*)
        '{'
      end
    end.new
  end
end
