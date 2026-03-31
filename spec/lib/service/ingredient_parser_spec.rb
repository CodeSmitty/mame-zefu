require 'rails_helper'

RSpec.describe 'IngredientParser', type: :service do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe, user: user, ingredients: ingredients_text) }
  let(:ingredient_parser) { Recipes::IngredientParser.new(recipe) }

  describe '#normalize_fractions' do
    let(:ingredients_text) { '' }

    it 'normalizes attached unicode fractions and mixed numbers' do
      normalized = ingredient_parser.send(:normalize_fractions, '1¼ cups flour and 2 1/2 cups milk')

      expect(normalized).to eq('5/4 cups flour and 5/2 cups milk')
    end
  end

  describe '#parse_ingredients' do
    subject(:parsed_ingredients) { ingredient_parser.parse_ingredients }

    context 'with simple ingredients' do
      let(:ingredients_text) do
        <<~INGREDIENTS
          1 cup flour
          2 eggs
          1/2 cup sugar
        INGREDIENTS
      end

      it 'parses quantity, unit, and ingredient name' do
        expect(parsed_ingredients).to eq [
          { original: '1 cup flour', quantity: '1/1', unit: 'cup', ingredient: 'flour' },
          { original: '2 eggs', quantity: '2/1', unit: nil, ingredient: 'eggs' },
          { original: '1/2 cup sugar', quantity: '1/2', unit: 'cup', ingredient: 'sugar' }
        ]
      end
    end

    context 'with complex ingredients' do
      let(:ingredients_text) do
        <<~INGREDIENTS
          3 tablespoons olive oil
          1 (14 oz) can diced tomatoes
          A pinch of salt
        INGREDIENTS
      end

      it 'parses complex formats correctly' do # rubocop:disable RSpec/ExampleLength
        expect(parsed_ingredients).to eq [
          { original: '3 tablespoons olive oil', quantity: '3/1', unit: 'tablespoon', ingredient: 'olive oil' },
          { original: '1 (14 oz) can diced tomatoes', quantity: '1/1', unit: nil,
            ingredient: '(14 oz) can diced tomatoes' },
          { original: 'A pinch of salt', quantity: '1/1', unit: 'pinch', ingredient: 'salt' }
        ]
      end
    end

    context 'with invalid formats' do
      let(:ingredients_text) do
        <<~INGREDIENTS
          Just some text without numbers or units
          Another line that's not an ingredient format
        INGREDIENTS
      end

      it 'returns original text with default quantity and nil unit' do # rubocop:disable RSpec/ExampleLength
        expect(parsed_ingredients).to eq [
          { original: 'Just some text without numbers or units', quantity: '1/1', unit: nil,
            ingredient: 'Just some text without numbers or units' },
          { original: 'Another line that\'s not an ingredient format', quantity: '1/1', unit: nil,
            ingredient: 'Another line that\'s not an ingredient format' }
        ]
      end
    end

    context 'with unscalable ingredient text' do
      let(:ingredients_text) { 'Salt to taste' }

      it 'marks the ingredient as unscalable' do
        expect(parsed_ingredients).to eq [
          { original: 'Salt to taste', quantity: nil, unit: nil, ingredient: 'Salt to taste', unscalable: true }
        ]
      end
    end

    context 'with numeric text that falls back to regex parsing' do
      let(:ingredients_text) { '3 blorps mystery powder' }

      it 'parses quantity and ingredient without a unit' do
        expect(parsed_ingredients).to eq [
          { original: '3 blorps mystery powder', quantity: '3/1', unit: nil, ingredient: 'blorps mystery powder' }
        ]
      end
    end
  end

  describe '#unscalable_parse' do
    let(:ingredients_text) { '' }

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
    let(:ingredients_text) { '' }

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
