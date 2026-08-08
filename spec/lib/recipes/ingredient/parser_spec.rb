require 'rails_helper'

RSpec.describe Recipes::Ingredient::Parser, type: :service do
  subject(:ingredient_parser) { described_class.new(ingredient_text) }

  describe '#normalized_ingredient' do
    let(:ingredient_text) { '' }

    it 'normalizes attached unicode fractions and mixed numbers' do
      normalized = ingredient_parser.send(:normalized_ingredient, '1¼ cups flour and 2 1/2 cups milk')

      expect(normalized).to eq('5/4 cups flour and 5/2 cups milk')
    end
  end

  describe '#parse' do
    subject(:parsed_ingredient) { ingredient_parser.parse }

    context 'with simple ingredient text' do
      let(:ingredient_text) { '1 cup flour' }
      let(:expected_parse) do
        { original: '1 cup flour', quantity: '1/1', unit: 'cup', ingredient: 'flour' }
      end

      it 'parses quantity, unit, and ingredient name' do
        expect(parsed_ingredient).to eq(expected_parse)
      end
    end

    context 'with a complex ingredient' do
      let(:ingredient_text) { '3 tablespoons olive oil' }
      let(:expected_parse) do
        { original: '3 tablespoons olive oil', quantity: '3/1', unit: 'tablespoon', ingredient: 'olive oil' }
      end

      it 'parses quantity, unit, and ingredient text' do
        expect(parsed_ingredient).to eq(expected_parse)
      end
    end

    context 'with a container measurement' do
      let(:ingredient_text) { '1 (14 oz) can diced tomatoes' }
      let(:expected_parse) do
        { original: '1 (14 oz) can diced tomatoes', quantity: '1/1', unit: nil,
          ingredient: '(14 oz) can diced tomatoes' }
      end

      it 'preserves the container detail in the ingredient text' do
        expect(parsed_ingredient).to eq(expected_parse)
      end
    end

    context 'with a pinch measurement' do
      let(:ingredient_text) { 'A pinch of salt' }
      let(:expected_parse) do
        { original: 'A pinch of salt', quantity: '1/1', unit: 'pinch', ingredient: 'salt' }
      end

      it 'parses the pinch unit' do
        expect(parsed_ingredient).to eq(expected_parse)
      end
    end

    context 'with invalid format' do
      let(:ingredient_text) { 'Just some text without numbers or units' }
      let(:expected_parse) do
        { original: 'Just some text without numbers or units', quantity: '1/1', unit: nil,
          ingredient: 'Just some text without numbers or units' }
      end

      it 'returns original text with default quantity and nil unit' do
        expect(parsed_ingredient).to eq(expected_parse)
      end
    end

    context 'with unscalable ingredient text' do
      let(:ingredient_text) { 'Salt to taste' }
      let(:expected_parse) do
        { original: 'Salt to taste', quantity: nil, unit: nil, ingredient: 'Salt to taste', unscalable: true }
      end

      it 'marks the ingredient as unscalable' do
        expect(parsed_ingredient).to eq(expected_parse)
      end
    end

    context 'with numeric text that falls back to regex parsing' do
      let(:ingredient_text) { '3 blorps mystery powder' }
      let(:expected_parse) do
        { original: '3 blorps mystery powder', quantity: '3/1', unit: nil, ingredient: 'blorps mystery powder' }
      end

      it 'parses quantity and ingredient without a unit' do
        expect(parsed_ingredient).to eq(expected_parse)
      end
    end

    context 'with blank ingredient text' do
      let(:ingredient_text) { '   ' }

      it 'returns nil' do
        expect(parsed_ingredient).to be_nil
      end
    end
  end

  describe '.parse_ingredients' do
    subject(:parsed_ingredients) { described_class.parse_ingredients(recipe) }

    let(:user) { create(:user) }
    let(:recipe) { create(:recipe, user: user, ingredients: ingredients_text) }

    context 'with multiple ingredients' do
      let(:ingredients_text) do
        <<~INGREDIENTS
          1 cup flour
          2 eggs
          1/2 cup sugar
        INGREDIENTS
      end

      it 'parses each ingredient line' do
        expect(parsed_ingredients).to eq [
          { original: '1 cup flour', quantity: '1/1', unit: 'cup', ingredient: 'flour' },
          { original: '2 eggs', quantity: '2/1', unit: nil, ingredient: 'eggs' },
          { original: '1/2 cup sugar', quantity: '1/2', unit: 'cup', ingredient: 'sugar' }
        ]
      end
    end

    context 'with blank lines' do
      let(:ingredients_text) do
        <<~INGREDIENTS
          1 cup flour

          2 eggs
        INGREDIENTS
      end

      it 'ignores empty lines' do
        expect(parsed_ingredients).to eq [
          { original: '1 cup flour', quantity: '1/1', unit: 'cup', ingredient: 'flour' },
          { original: '2 eggs', quantity: '2/1', unit: nil, ingredient: 'eggs' }
        ]
      end
    end
  end

  describe '#unscalable_parse' do
    let(:ingredient_text) { '' }

    it 'returns the original ingredient as unscalable metadata' do # rubocop:disable RSpec/ExampleLength
      parsed = ingredient_parser.send(:unscalable_parse, 'Salt to taste')

      expect(parsed).to eq(
        original: 'Salt to taste',
        quantity: nil,
        unit: nil,
        ingredient: 'Salt to taste',
        unscalable: true
      )
    end
  end

  describe '#try_regex_fallback' do
    let(:ingredient_text) { '' }

    it 'returns parsed fallback data with original ingredient preserved' do # rubocop:disable RSpec/ExampleLength
      parsed = ingredient_parser.send(:try_regex_fallback, '3 mystery powder', '3 mystery powder')

      expect(parsed).to eq(
        original: '3 mystery powder',
        quantity: '3/1',
        unit: nil,
        ingredient: 'mystery powder'
      )
    end
  end
end
