require 'rails_helper'

RSpec.describe 'Ingredient Parser', type: :feature do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe, user: user, ingredients: ingredients_text) }
  let(:ingredient_parser) { Recipes::IngredientParser.new(recipe) }

  describe '#parse_ingredients' do
    subject { ingredient_parser.parse_ingredients }

    context 'with simple ingredients' do
      let(:ingredients_text) do
        <<~INGREDIENTS
          1 cup flour
          2 eggs
          1/2 cup sugar
        INGREDIENTS
      end

      it 'parses quantity, unit, and ingredient name' do
        expect(subject).to eq [
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

      it 'parses complex formats correctly' do
        expect(subject).to eq [
          { original: '3 tablespoons olive oil', quantity: '3/1', unit: 'tablespoon', ingredient: 'olive oil' },
          { original: '1 (14 oz) can diced tomatoes', quantity: '1/1', unit: nil, ingredient: '(14 oz) can diced tomatoes' },
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

      it 'returns original text with nil for quantity and unit' do
        expect(subject).to eq [
          { original: 'Just some text without numbers or units', quantity: nil, unit: nil, ingredient: 'Just some text without numbers or units' },
          { original: 'Another line that\'s not an ingredient format', quantity: nil, unit: nil, ingredient: 'Another line that\'s not an ingredient format' }
        ]
      end
    end
  end
end