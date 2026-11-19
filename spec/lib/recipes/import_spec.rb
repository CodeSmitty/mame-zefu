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
  end

  describe '#recipe' do
    subject(:import) { described_class.new(uri: uri) }

    let!(:stub) { stub_request(:get, uri.to_s).to_return(body: html_body) }
    let(:html_body) { '<html><body>Recipe content</body></html>' }
    let(:recipe_class) { Recipes::Import::JsonSchema }
    let(:recipe_instance) { instance_double(recipe_class) }
    let(:recipe) { build(:recipe) }

    before do
      allow(Recipes::Import::RecipeScrapers).to receive(:supported_host?).with(uri.host).and_return(false)
      allow(recipe_class).to receive(:new).and_return(recipe_instance)
      allow(recipe_instance).to receive(:recipe).and_return(recipe)
    end

    it 'fetches the HTML body' do
      import.recipe
      expect(stub).to have_been_requested
    end

    it 'fetches the page with a browser-compatible user agent' do
      import.recipe
      expect(stub.with(headers: { 'User-Agent' => described_class::USER_AGENT })).to have_been_requested
    end

    it 'parses the document with Nokogiri' do
      import.recipe
      expect(import.send(:document)).to be_a(Nokogiri::HTML::Document)
    end

    it 'returns the recipe from the recipe class instance' do
      expect(import.recipe).to eq(recipe)
    end

    context 'when no recipe details are extracted' do
      let(:recipe) { Recipe.new }

      it 'raises NotFoundError' do
        expect { import.recipe }
          .to raise_error(Recipes::Import::NotFoundError, 'No recipe details found on the page')
      end
    end

    context 'when the page redirects' do
      let!(:stub) { stub_request(:get, uri.to_s).to_return(status: 302, headers: { 'Location' => '/new-recipe' }) }
      let!(:redirect_stub) { stub_request(:get, 'https://example.com/new-recipe').to_return(body: html_body) }

      it 'fetches the redirected page' do
        import.recipe
        expect(redirect_stub).to have_been_requested
      end
    end

    context 'when the page request fails' do
      let!(:stub) { stub_request(:get, uri.to_s).to_return(status: 403) }

      it 'reports the HTTP status' do
        expect { import.recipe }.to raise_error(Recipes::Import::FetchError, /HTTP 403/)
      end
    end

    context 'when redirects exceed the limit' do
      let!(:stub) { stub_request(:get, uri.to_s).to_return(status: 302, headers: { 'Location' => url }) }

      it 'reports the redirect failure' do
        expect { import.recipe }.to raise_error(Recipes::Import::FetchError, /HTTP 302/)
      end
    end
  end

  describe 'RecipeScrapers fallback' do
    subject(:import) { described_class.new(uri: uri) }

    let(:scraper) { instance_double(Recipes::Import::RecipeScrapers) }
    let(:json_html) do
      <<~HTML
        <script type="application/ld+json">
          {"@graph":[{"@type":"Recipe","name":"Fallback cake","recipeIngredient":["Flour"]}]}
        </script>
      HTML
    end
    let!(:page_stub) { stub_request(:get, url).to_return(body: json_html) }

    before do
      allow(Recipes::Import::RecipeScrapers).to receive(:supported_host?).with(uri.host).and_return(true)
      allow(Recipes::Import::RecipeScrapers).to receive(:new).with(nil, uri).and_return(scraper)
    end

    context 'when the scraper succeeds' do
      before { allow(scraper).to receive(:recipe).and_return(Recipe.new(name: 'Scraped cake')) }

      it 'returns the scraper recipe without fetching a document' do
        expect(import.recipe.name).to eq('Scraped cake')
        expect(page_stub).not_to have_been_requested
      end
    end

    context 'when the scraper fails' do
      before do
        allow(scraper).to receive(:recipe).and_raise(Recipes::Import::RecipeScrapers::NotFoundError, 'scrape failed')
      end

      it 'returns the JSON-LD recipe' do
        expect(import.recipe.attributes).to include('name' => 'Fallback cake', 'ingredients' => 'Flour')
      end
    end

    context 'when the scraper returns no recipe details' do
      before { allow(scraper).to receive(:recipe).and_return(Recipe.new(source: url)) }

      it 'returns the JSON-LD recipe' do
        expect(import.recipe.name).to eq('Fallback cake')
      end
    end

    context 'when both importers fail' do
      let(:json_html) { '<html><body>No recipe</body></html>' }

      before do
        allow(scraper).to receive(:recipe).and_raise(Recipes::Import::RecipeScrapers::NotFoundError, 'scrape failed')
      end

      it 'reports the JSON-LD failure' do
        expect { import.recipe }.to raise_error(Recipes::Import::JsonSchema::NotFoundError)
      end
    end
  end

  describe 'fallback after a scraper process failure' do
    let(:status) { instance_double(Process::Status, success?: false) }

    before do
      allow(Recipes::Import::RecipeScrapers).to receive(:supported_host?).with(uri.host).and_return(true)
      allow(Open3).to receive(:capture3)
        .with(Recipes::Import::RecipeScrapers::SCRAPER_PATH, url)
        .and_return(['', 'scraper failed', status])
      stub_request(:get, url).to_return(body: <<~HTML)
        <script type="application/ld+json">
          {"@type":"Recipe","name":"Fallback cake"}
        </script>
      HTML
    end

    it 'tries JSON-LD when scraper initialization raises' do
      expect(described_class.new(uri: uri).recipe.name).to eq('Fallback cake')
    end
  end

  describe '#recipe_class' do
    subject(:import) { described_class.new(uri: uri) }

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
