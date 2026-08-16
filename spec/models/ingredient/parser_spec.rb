require 'rails_helper'

RSpec.describe Ingredient::Parser, type: :service do
  subject(:ingredient_parser) { described_class.new(ingredient_text) }

  describe '#parse' do
    subject(:parsed_ingredient) { ingredient_parser.parse }

    shared_examples 'a quantity-less ingredient' do
      it 'returns a nil quantity and unit' do
        expect(parsed_ingredient).to have_attributes(quantity: nil, unit: nil, name: ingredient_text)
      end
    end

    context 'with attached unicode fractions and mixed numbers' do
      let(:ingredient_text) { '1¼ cups flour and 2 1/2 cups milk' }

      it 'normalizes quantity and parses it through the public parse API' do
        expect(parsed_ingredient).to have_attributes(quantity: '5/4', unit: 'cup', name: 'flour and 5/2 cups milk')
      end
    end

    context 'with simple ingredient text' do
      let(:ingredient_text) { '1 cup flour' }

      it 'parses quantity, unit, and ingredient name' do
        expect(parsed_ingredient).to have_attributes(quantity: '1/1', unit: 'cup', name: 'flour')
      end
    end

    context 'with the standard cup abbreviation' do
      let(:ingredient_text) { '1 c flour' }

      it 'parses the abbreviation as a cup' do
        expect(parsed_ingredient).to have_attributes(quantity: '1/1', unit: 'cup', name: 'flour')
      end
    end

    context 'with a pint unit' do
      let(:ingredient_text) { '1 pt milk' }

      it 'parses the pint abbreviation' do
        expect(parsed_ingredient).to have_attributes(quantity: '1/1', unit: 'pint', name: 'milk')
      end
    end

    context 'with a complex ingredient' do
      let(:ingredient_text) { '3 tablespoons olive oil' }

      it 'parses quantity, unit, and ingredient text' do
        expect(parsed_ingredient).to have_attributes(quantity: '3/1', unit: 'tablespoon', name: 'olive oil')
      end
    end

    context 'with a container measurement' do
      let(:ingredient_text) { '1 (14 oz) can diced tomatoes' }

      it 'preserves the container detail in the ingredient text' do
        expect(parsed_ingredient).to have_attributes(quantity: '1/1', unit: nil, name: '(14 oz) can diced tomatoes')
      end
    end

    context 'with a pinch measurement' do
      let(:ingredient_text) { 'A pinch of salt' }

      it 'parses the pinch unit' do
        expect(parsed_ingredient).to have_attributes(quantity: '1/1', unit: 'pinch', name: 'salt')
      end
    end

    context 'with a range measurement' do
      let(:ingredient_text) { '1 to 2 tsp sugar' }

      it 'parses the quantity range, unit, and ingredient text' do
        expect(parsed_ingredient).to have_attributes(quantity: '1/1', quantity_max: '2/1', unit: 'tsp', name: 'sugar')
      end
    end

    context 'with a range followed by ingredient text instead of a unit' do
      let(:ingredient_text) { '3 to 4 bananas, finely crushed' }

      it 'keeps the range and treats the remaining text as ingredient content' do
        expect(parsed_ingredient).to have_attributes(quantity: '3/1', quantity_max: '4/1', unit: nil,
                                                     name: 'bananas, finely crushed')
      end
    end

    context 'when unit recognition raises during range parsing' do
      let(:ingredient_text) { '3 to 4 blorps finely crushed' }

      before do
        allow(Ingreedy).to receive(:parse).with('1 blorps sugar').and_raise(Ingreedy::ParseFailed)
      end

      it 'treats the candidate as a non-unit and keeps the range text as ingredient content' do
        expect(parsed_ingredient).to have_attributes(quantity: '3/1', quantity_max: '4/1', unit: nil,
                                                     name: 'blorps finely crushed')
      end
    end

    context 'with a hyphenated fractional range' do
      let(:ingredient_text) { '1/4-1/2 tsp Cayenne Pepper' }

      it 'parses the fraction range without mangling the second fraction' do
        expect(parsed_ingredient).to have_attributes(quantity: '1/4', quantity_max: '1/2', unit: 'tsp',
                                                     name: 'Cayenne Pepper')
      end
    end

    context 'with a unit followed by a trailing comma' do
      let(:ingredient_text) { '2 tablespoons, minced fresh parsley leaves' }

      it 'parses the unit and strips the comma from the ingredient text' do
        expect(parsed_ingredient).to have_attributes(quantity: '2/1', unit: 'tablespoon',
                                                     name: 'minced fresh parsley leaves')
      end
    end

    context 'with invalid format' do
      let(:ingredient_text) { 'Just some text without numbers or units' }

      it 'returns the ingredient name with a nil quantity and unit' do
        expect(parsed_ingredient).to have_attributes(quantity: nil, unit: nil,
                                                     name: 'Just some text without numbers or units')
      end
    end

    context 'with ingredient text that has no quantity or unit' do
      context 'with optional garnish text' do
        let(:ingredient_text) { 'Additional fresh blueberries, optional' }

        it_behaves_like 'a quantity-less ingredient'
      end

      context 'with single-word ingredient text' do
        let(:ingredient_text) { 'ice' }

        it_behaves_like 'a quantity-less ingredient'
      end

      context 'with seasoning text' do
        let(:ingredient_text) { 'Salt and pepper, for taste' }

        it_behaves_like 'a quantity-less ingredient'
      end
    end

    context 'when ingreedy cannot parse a non-numeric ingredient' do
      let(:ingredient_text) { 'fresh oregano leaves' }

      before do
        allow(Ingreedy).to receive(:parse).and_raise(Ingreedy::ParseFailed)
      end

      it 'falls back to the default parse output' do
        expect(parsed_ingredient).to have_attributes(quantity: nil, unit: nil, name: 'fresh oregano leaves')
      end
    end

    context 'with free-form ingredient text' do
      let(:ingredient_text) { 'Salt to taste' }

      it 'returns a quantity-less ingredient' do
        expect(parsed_ingredient).to have_attributes(quantity: nil, unit: nil, name: 'Salt to taste')
      end
    end

    context 'with numeric text that falls back to regex parsing' do
      let(:ingredient_text) { '3 blorps mystery powder' }

      it 'parses quantity and ingredient without a unit' do
        expect(parsed_ingredient).to have_attributes(quantity: '3/1', unit: nil, name: 'blorps mystery powder')
      end
    end

    context 'when ingreedy fails on numeric text' do
      let(:ingredient_text) { '3 mystery powder' }

      before do
        allow(Ingreedy).to receive(:parse).and_raise(Ingreedy::ParseFailed)
      end

      it 'falls back to regex parsing through the public parse API' do
        expect(parsed_ingredient).to have_attributes(quantity: '3/1', unit: nil, name: 'mystery powder')
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
        expect(parsed_ingredients).to all be_a(Ingredient)
        expect(parsed_ingredients.map(&:name)).to eq %w[flour eggs sugar]
        expect(parsed_ingredients.map(&:quantity)).to eq %w[1/1 2/1 1/2]
        expect(parsed_ingredients.map(&:unit)).to eq ['cup', nil, 'cup']
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
        expect(parsed_ingredients.map(&:name)).to eq %w[flour eggs]
      end
    end
  end
end
