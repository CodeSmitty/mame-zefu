# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Import::RecipeScrapers do
  subject(:import) { described_class.new(document, source) }

  let(:document) { Nokogiri::HTML('<html><body>Test</body></html>') }
  let(:source) { 'https://example.com/recipe' }
  let(:scrape_path) { Rails.root.join('bin/scrape').to_s }
  let(:status_success) { instance_double(Process::Status, success?: true) }

  let(:recipe_json) do
    {
      'title' => 'Test Recipe',
      'image' => 'https://example.com/image.jpg',
      'yields' => '4 servings',
      'prep_time' => '10',
      'cook_time' => '20',
      'total_time' => '30',
      'category' => 'Dessert, Cake',
      'description' => 'Tasty',
      'ingredient_groups' => [
        {
          'name' => 'Cake',
          'purpose' => 'Main',
          'ingredients' => ['2c flour']
        }
      ],
      'instructions_list' => ['Step 1']
    }
  end

  before do
    allow(Open3).to receive(:capture3)
      .and_return([recipe_json.to_json, '', status_success])
  end

  it 'calls bin/scrape with source and html' do
    import

    expect(Open3).to have_received(:capture3).with(
      scrape_path,
      source.to_s,
      stdin_data: document.to_html
    )
  end

  it 'parses the json output' do
    expect(import.send(:recipe_json)).to eq(recipe_json)
  end

  context 'when scrape fails' do
    let(:status_failure) { instance_double(Process::Status, success?: false) }

    before do
      allow(Open3).to receive(:capture3)
        .and_return(['', 'boom', status_failure])
    end

    it 'raises NotFoundError with stderr' do
      expect { import }
        .to raise_error(Recipes::Import::RecipeScrapers::NotFoundError, /boom/)
    end
  end

  context 'when json is invalid' do
    before do
      allow(Open3).to receive(:capture3)
        .and_return(['not-json', '', status_success])
    end

    it 'raises NotFoundError' do
      expect { import }
        .to raise_error(Recipes::Import::RecipeScrapers::NotFoundError)
    end
  end
end
