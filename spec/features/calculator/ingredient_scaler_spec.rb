require 'rails_helper'

RSpec.describe 'Ingredient Scaler' do
  let(:ingredient_scaler) { Recipes::IngredientScaler.new }

  describe '#scale_ingredient' do
    subject(:scaled_result) { ingredient_scaler.scale_ingredient(parsed_ingredient, multiplier) }

    let(:multiplier) { 2 }

    context 'when ingredient should be scaled' do
      let(:parsed_ingredient) do
        { original: '1 cup flour', quantity: Fractional.new('1/1'), unit: 'cup', ingredient: 'flour' }
      end

      it 'scales the quantity and updates the description' do
        result = scaled_result
        expect(result[:scaled_quantity]).to eq '2/1'
        expect(result[:scaled_description]).to eq '2/1 cup flour'
        expect(result[:scale_applied]).to be true
      end

      it 'formats the scaled_description without unit' do
        parsed_without_unit = { original: '1/2 sugar', quantity: Fractional.new('1/2'), unit: nil, ingredient: 'sugar' }
        result = ingredient_scaler.scale_ingredient(parsed_without_unit, multiplier)
        expect(result[:scaled_description]).to eq '1/1 sugar'
      end
    end

    context 'when ingredient should not be scaled' do
      let(:parsed_ingredient) do
        { original: 'A pinch of salt', quantity: nil, unit: nil, ingredient: 'A pinch of salt' }
      end

      it 'does not scale the quantity and keeps the original description' do
        result = scaled_result
        expect(result[:scaled_quantity]).to be_nil
        expect(result[:scaled_description]).to eq 'A pinch of salt'
        expect(result[:scale_applied]).to be false
      end
    end
  end

  describe '#scale_ingredients' do
    subject(:scaled_results) { ingredient_scaler.scale_ingredients(parsed_ingredients, multiplier) }

    let(:multiplier) { 2 }
    let(:parsed_ingredients) do
      [
        { original: '1 cup flour', quantity: Fractional.new('1/1'), unit: 'cup', ingredient: 'flour' },
        { original: '2 tablespoons butter', quantity: Fractional.new('2/1'), unit: 'tablespoons',
          ingredient: 'butter' },
        { original: 'A pinch of salt', quantity: nil, unit: nil, ingredient: 'A pinch of salt' }
      ]
    end

    it 'maps through parsed_ingredients and scales each one' do
      results = scaled_results

      expect(results).to be_an(Array)
      expect(results.length).to eq(3)

      expect(results[0][:scaled_quantity]).to eq('2/1')
      expect(results[0][:scaled_description]).to eq('2/1 cup flour')
      expect(results[0][:scale_applied]).to be true
    end
  end
end
