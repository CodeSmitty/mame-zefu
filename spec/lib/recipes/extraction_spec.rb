# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Extraction do
  let(:valid_image_file) { Rails.root.join('spec/fixtures/files/test.png').to_s }

  describe '.from_file' do
    subject(:from_file) { described_class.from_file(valid_image_file) }

    let(:extractor_payload) { { 'name' => 'Cake' } }
    let(:recipe_model) { Recipe.new(name: 'Cake') }
    let(:extraction) { described_class.send(:new, image_file: valid_image_file) }
    let(:extractor) { instance_double(Recipes::Extraction::Anthropic, call: extractor_payload) }

    before do
      allow(described_class).to receive(:new).with(image_file: valid_image_file).and_return(extraction)
      allow(extraction).to receive(:extractor).and_return(extractor)
      allow(Recipes::Extraction::RecipeBuilder).to receive(:build).with(extractor_payload).and_return(recipe_model)
    end

    it 'returns an unsaved recipe model from extracted payload' do
      expect(from_file).to be_a(Recipe)
      expect(from_file).not_to be_persisted
      expect(from_file).to eq(recipe_model)
    end
  end

  describe '.enabled?' do
    let(:user) { build_stubbed(:user) }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(Feature).to receive(:recipe_extraction_enabled?)
    end

    it 'returns true when API key is set and feature is enabled' do
      allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return('test-key')
      allow(Feature).to receive(:recipe_extraction_enabled?).with(user).and_return(true)

      expect(described_class.enabled?(user)).to be(true)
    end

    it 'returns false when Anthropic API key is missing' do
      allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return(nil)

      expect(described_class.enabled?(user)).to be(false)
      expect(Feature).not_to have_received(:recipe_extraction_enabled?)
    end

    it 'returns false when feature is disabled' do
      allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return('test-key')
      allow(Feature).to receive(:recipe_extraction_enabled?).with(user).and_return(false)

      expect(described_class.enabled?(user)).to be(false)
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

  describe 'extractor memoization' do
    let(:service) { described_class.send(:new, image_file: valid_image_file) }
    let(:extractor_payload) { { 'name' => 'Bread' } }
    let(:extractor) { instance_double(Recipes::Extraction::Anthropic, call: extractor_payload) }

    before do
      allow(Recipes::Extraction::Anthropic).to receive(:new)
        .with(image_file: valid_image_file, media_type: anything)
        .and_return(extractor)
      allow(Recipes::Extraction::RecipeBuilder).to receive(:build).and_return(Recipe.new(name: 'Bread'))
    end

    it 'memoizes anthropic extractor instance' do
      service.send(:recipe)
      service.send(:recipe)

      expect(Recipes::Extraction::Anthropic).to have_received(:new).once
    end
  end

  describe 'Error' do
    it 'inherits from StandardError' do
      expect(described_class::Error).to be < StandardError
    end
  end
end
