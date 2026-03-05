# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Extraction do
  let(:valid_image_file) { Rails.root.join('spec/fixtures/files/test.png').to_s }

  describe '.from_file' do
    subject(:from_file) { described_class.from_file(valid_image_file) }

    let(:recipe_payload) { { 'name' => 'Cake' } }
    let(:extraction) { instance_double(described_class, recipe: recipe_payload) }

    before do
      allow(described_class).to receive(:new).with(image_file: valid_image_file).and_return(extraction)
    end

    it 'builds an extraction and returns recipe output' do
      expect(from_file).to eq(recipe_payload)
    end
  end

  describe '#recipe' do
    subject(:recipe) { service.recipe }

    let(:service) { described_class.send(:new, image_file: valid_image_file) }
    let(:extractor_payload) { { 'name' => 'Bread' } }
    let(:extractor) { instance_double(Recipes::Extraction::Anthropic, recipe: extractor_payload) }

    before do
      allow(Recipes::Extraction::Anthropic).to receive(:new)
        .with(image_file: valid_image_file, media_type: anything)
        .and_return(extractor)
    end

    it 'delegates recipe retrieval to anthropic extractor' do
      expect(recipe).to eq(extractor_payload)
    end

    it 'memoizes extractor instance across multiple recipe calls' do
      recipe
      recipe

      expect(Recipes::Extraction::Anthropic).to have_received(:new).once
    end

    it 'returns same extractor result on consecutive calls' do
      expect(recipe).to eq(service.recipe)
    end
  end

  describe 'validation' do
    context 'when file type is unsupported' do
      before do
        allow(Marcel::MimeType).to receive(:for).and_return('application/pdf')
      end

      it 'raises an unsupported type error' do
        expect { described_class.send(:new, image_file: valid_image_file) }
          .to raise_error(described_class::Error, /Unsupported file type/)
      end
    end

    context 'when file size exceeds max image size' do
      before do
        allow(File).to receive(:size).with(valid_image_file).and_return(described_class::MAX_IMAGE_SIZE + 1)
      end

      it 'raises an oversized image error' do
        expect { described_class.send(:new, image_file: valid_image_file) }
          .to raise_error(described_class::Error, /Image is too large/)
      end
    end
  end

  describe 'Error' do
    it 'inherits from StandardError' do
      expect(described_class::Error).to be < StandardError
    end
  end
end
