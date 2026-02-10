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
end
