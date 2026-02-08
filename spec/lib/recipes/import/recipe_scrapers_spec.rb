# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Import::RecipeScrapers do
  subject(:import) { described_class.new(document, source) }

  let(:document) { Nokogiri::HTML('<html><body>Test</body></html>') }
  let(:source) { 'https://example.com/recipe' }
  let(:scrape_path) { Recipes::Import::RecipeScrapers::SCRAPER_PATH }
  let(:scrape_status) { instance_double(Process::Status, success?: scrape_success?) }
  let(:scrape_success?) { true }
  let(:scrape_error) { '' }
  let(:scrape_output) { recipe_hash.to_json }

  let(:recipe_hash) { { title: 'Test Recipe' } }

  before do
    allow(Open3).to receive(:capture3)
      .with(scrape_path, source.to_s, stdin_data: document.to_html)
      .and_return([scrape_output, scrape_error, scrape_status])
  end

  describe '.supported_host?' do
    let(:host) { 'example.com' }
    let(:cache_key) { "recipe_scrapers/supported_host/#{host}" }

    before do
      Rails.cache.clear
      allow(described_class).to receive(:system)
        .with(scrape_path, '--check-host', host.to_s, out: File::NULL, err: File::NULL)
        .and_return(system_status)
    end

    context 'when the scrape command succeeds' do
      let(:system_status) { true }

      it 'returns true' do
        expect(described_class.supported_host?(host)).to be(true)
      end

      it 'caches the result' do
        allow(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 1.hour).and_call_original
        described_class.supported_host?(host)
        expect(Rails.cache).to have_received(:fetch).with(cache_key, expires_in: 1.hour)
      end

      it 'does not call system on subsequent calls' do
        # First call should invoke system
        expect(described_class.supported_host?(host)).to be(true)
        expect(described_class).to have_received(:system).once

        # Second call should use cache and not invoke system again
        expect(described_class.supported_host?(host)).to be(true)
        expect(described_class).to have_received(:system).once
      end
    end

    context 'when the scrape command fails' do
      let(:system_status) { false }

      it 'returns false' do
        expect(described_class.supported_host?(host)).to be(false)
      end

      it 'caches the result' do
        allow(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 1.hour).and_call_original
        described_class.supported_host?(host)
        expect(Rails.cache).to have_received(:fetch).with(cache_key, expires_in: 1.hour)
      end
    end
  end

  context 'when scrape fails' do
    let(:scrape_success?) { false }
    let(:scrape_error) { 'boom' }

    it 'raises NotFoundError with stderr' do
      expect { import }
        .to raise_error(Recipes::Import::RecipeScrapers::NotFoundError, /boom/)
    end
  end

  context 'when json is invalid' do
    let(:scrape_output) { 'not-json' }

    it 'raises NotFoundError' do
      expect { import }
        .to raise_error(Recipes::Import::RecipeScrapers::NotFoundError)
    end
  end

  describe '#recipe_json' do
    it 'parses the json output' do
      expect(import.send(:recipe_json)).to eq(recipe_hash.deep_stringify_keys)
    end
  end

  describe '#recipe_name' do
    let(:recipe_name) { 'My Cake' }
    let(:recipe_hash) { { title: recipe_name } }

    it 'extracts the recipe name' do
      expect(import.recipe_name).to eq(recipe_name)
    end
  end

  describe '#recipe_image_src' do
    let(:recipe_image_src) { 'https://example.com/image.jpg' }
    let(:recipe_hash) { { image: recipe_image_src } }

    it 'extracts the recipe image src' do
      expect(import.recipe_image_src).to eq(recipe_image_src)
    end

    context 'when image is not a full url' do
      let(:recipe_hash) { { image: '/images/cake.jpg' } }

      it 'returns nil' do
        expect(import.recipe_image_src).to be_nil
      end
    end
  end

  describe '#recipe_yield' do
    let(:recipe_yield) { '4 servings' }
    let(:recipe_hash) { { yields: recipe_yield } }

    it 'extracts the recipe yield' do
      expect(import.recipe_yield).to eq(recipe_yield)
    end
  end

  describe '#recipe_prep_time' do
    let(:recipe_prep_time) { 10 }
    let(:recipe_hash) { { prep_time: recipe_prep_time } }

    it 'extracts the recipe prep time' do
      expect(import.recipe_prep_time).to eq("#{recipe_prep_time} minutes")
    end
  end

  describe '#recipe_cook_time' do
    let(:recipe_cook_time) { 20 }
    let(:recipe_hash) { { cook_time: recipe_cook_time } }

    it 'extracts the recipe cook time' do
      expect(import.recipe_cook_time).to eq("#{recipe_cook_time} minutes")
    end
  end

  describe '#recipe_total_time' do
    let(:recipe_total_time) { 30 }
    let(:recipe_hash) { { total_time: recipe_total_time } }

    it 'extracts the recipe total time' do
      expect(import.recipe_total_time).to eq("#{recipe_total_time} minutes")
    end
  end

  describe '#recipe_category_names' do
    let(:recipe_hash) { { category: 'dessert, cake' } }

    it 'extracts the recipe category names' do
      expect(import.recipe_category_names).to contain_exactly('Dessert', 'Cake')
    end
  end

  describe '#recipe_description' do
    let(:recipe_description) { 'Tasty' }
    let(:recipe_hash) { { description: recipe_description } }

    it 'extracts the recipe description' do
      expect(import.recipe_description).to eq(recipe_description)
    end
  end

  describe '#recipe_ingredients' do
    let(:recipe_hash) do
      {
        ingredient_groups: [
          {
            purpose: 'Cake',
            ingredients: ['2c flour', '1c sugar']
          }
        ]
      }
    end

    it 'extracts the recipe ingredients' do
      expect(import.recipe_ingredients).to eq("CAKE\n2c flour\n1c sugar")
    end

    context 'when the group has no purpose' do
      let(:recipe_hash) do
        {
          ingredient_groups: [
            {
              purpose: nil,
              ingredients: ['2c flour', '1c sugar']
            }
          ]
        }
      end

      it 'omits the group header' do
        expect(import.recipe_ingredients).to eq("2c flour\n1c sugar")
      end
    end

    context 'when there are no ingredient groups' do
      let(:recipe_hash) { { ingredients: ['2c flour', '1c sugar'] } }

      it 'joins the ingredients with newlines' do
        expect(import.recipe_ingredients).to eq("2c flour\n1c sugar")
      end
    end
  end

  describe '#recipe_directions' do
    let(:recipe_hash) { { instructions_list: ['Step 1', 'Step 2'] } }

    it 'extracts the recipe directions' do
      expect(import.recipe_directions).to eq("Step 1\n\nStep 2")
    end

    context 'when there are no instruction groups' do
      let(:recipe_hash) { { instructions: 'Mix and bake.' } }

      it 'returns the instructions as is' do
        expect(import.recipe_directions).to eq('Mix and bake.')
      end
    end
  end
end
