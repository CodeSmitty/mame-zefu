require 'rails_helper'

RSpec.describe Recipes::Ingredient::Parser, type: :service do
  subject(:ingredient_parser) { described_class.new(ingredient_text) }

  describe '#parse' do
    subject(:parsed_ingredient) { ingredient_parser.parse }

    context 'with attached unicode fractions and mixed numbers' do
      let(:ingredient_text) { '1¼ cups flour and 2 1/2 cups milk' }
      let(:expected_parse) do
        { original: '1¼ cups flour and 2 1/2 cups milk', quantity: '5/4', unit: 'cup',
          ingredient: 'flour and 5/2 cups milk' }
      end

      it 'normalizes quantity and parses it through the public parse API' do
        expect(parsed_ingredient).to eq(expected_parse)
      end
    end

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

    context 'with a range measurement' do
      let(:ingredient_text) { '1 to 2 tsp sugar' }
      let(:expected_parse) do
        { original: '1 to 2 tsp sugar', quantity: '1/1', quantity_max: '2/1', unit: 'tsp', ingredient: 'sugar' }
      end

      it 'parses the quantity range, unit, and ingredient text' do
        expect(parsed_ingredient).to eq(expected_parse)
      end
    end

    context 'with a hyphenated fractional range' do
      let(:ingredient_text) { '1/4-1/2 tsp Cayenne Pepper' }
      let(:expected_parse) do
        { original: '1/4-1/2 tsp Cayenne Pepper', quantity: '1/4', quantity_max: '1/2', unit: 'tsp',
          ingredient: 'Cayenne Pepper' }
      end

      it 'parses the fraction range without mangling the second fraction' do
        expect(parsed_ingredient).to eq(expected_parse)
      end
    end

    context 'with a unit followed by a trailing comma' do
      let(:ingredient_text) { '2 tablespoons, minced fresh parsley leaves' }
      let(:expected_parse) do
        { original: '2 tablespoons, minced fresh parsley leaves', quantity: '2/1', unit: 'tablespoon',
          ingredient: 'minced fresh parsley leaves' }
      end

      it 'parses the unit and strips the comma from the ingredient text' do
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

    context 'when ingreedy cannot parse a non-numeric ingredient' do
      let(:ingredient_text) { 'fresh oregano leaves' }
      let(:expected_parse) do
        { original: 'fresh oregano leaves', quantity: '1/1', unit: nil, ingredient: 'fresh oregano leaves' }
      end

      before do
        allow(Ingreedy).to receive(:parse).and_raise(Ingreedy::ParseFailed)
      end

      it 'falls back to the default parse output' do
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

    context 'when ingreedy fails on numeric text' do
      let(:ingredient_text) { '3 mystery powder' }
      let(:expected_parse) do
        { original: '3 mystery powder', quantity: '3/1', unit: nil, ingredient: 'mystery powder' }
      end

      before do
        allow(Ingreedy).to receive(:parse).and_raise(Ingreedy::ParseFailed)
      end

      it 'falls back to regex parsing through the public parse API' do
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
end
