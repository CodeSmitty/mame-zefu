# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Import do
  let(:url) { 'https://example.com/recipe' }
  let(:uri) { URI(url) }

  describe '.from_url' do
    it 'creates an instance with the URI' do
      instance = described_class.from_url(url)
      expect(instance.send(:uri)).to eq(uri)
    end

    it 'passes force_json_schema option' do
      instance = described_class.from_url(url, force_json_schema: true)
      expect(instance.send(:force_json_schema)).to be true
    end
  end

  describe '#recipe' do
    subject(:import) { described_class.new(uri: uri) }

    let!(:stub) { stub_request(:get, uri.to_s).to_return(body: html_body) }
    let(:html_body) { '<html><body>Recipe content</body></html>' }
    let(:recipe_class) { Recipes::Import::JsonSchema }
    let(:recipe_instance) { instance_double(recipe_class) }
    let(:recipe) { build(:recipe) }

    before do
      allow(recipe_class).to receive(:new).and_return(recipe_instance)
      allow(recipe_instance).to receive(:recipe).and_return(recipe)
    end

    it 'fetches the HTML body' do
      import.recipe
      expect(stub).to have_been_requested
    end

    it 'parses the document with Nokogiri' do
      import.recipe
      expect(import.send(:document)).to be_a(Nokogiri::HTML::Document)
    end

    it 'returns the recipe from the recipe class instance' do
      expect(import.recipe).to eq(recipe)
    end
  end

  describe '#recipe_class' do
    subject(:import) { described_class.new(uri: uri, force_json_schema: force_json_schema) }

    let(:force_json_schema) { false }
    let(:json_schema_class) { Recipes::Import::JsonSchema }
    let(:recipe_scraper_class) { Recipes::Import::RecipeScrapers }
    let(:recipe_scraper_supported?) { false }

    before do
      allow(recipe_scraper_class)
        .to receive(:supported_host?)
        .with(uri.host)
        .and_return(recipe_scraper_supported?)
    end

    context 'when host is in RECIPE_CLASSES' do
      let(:url) { 'https://www.gordonramsay.com/recipe' }

      it 'returns the specific class' do
        expect(import.send(:recipe_class)).to eq(Recipes::Import::GordonRamsay)
      end

      context 'when force_json_schema is true' do
        let(:force_json_schema) { true }

        it 'returns JsonSchema' do
          expect(import.send(:recipe_class)).to eq(json_schema_class)
        end
      end
    end

    context 'when host is supported by RecipeScrapers' do
      let(:recipe_scraper_supported?) { true }

      it 'returns RecipeScrapers' do
        expect(import.send(:recipe_class)).to eq(recipe_scraper_class)
      end
    end

    context 'when host is not configured or supported' do
      let(:url) { 'https://unknownsite.com/recipe' }

      it 'returns JsonSchema' do
        expect(import.send(:recipe_class)).to eq(json_schema_class)
      end
    end
  end
end
