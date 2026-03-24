require 'rails_helper'

RSpec.describe 'Ingredient Calculator' do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe, user: user, ingredients: ingredients_text) }
  let(:ingredient_calculator) { Recipes::IngredientCalculator.new(recipe) }

  describe '#calculate_total_ingredients' do
    subject(:calculated_ingredients) { ingredient_calculator.calculate_total_ingredients(recipe, multiplier) }

    context 'with simple scalable ingredients' do
      let(:multiplier) { 2 }
      let(:ingredients_text) do
        <<~INGREDIENTS
          1 cup flour
          2 tablespoons butter
        INGREDIENTS
      end
      let(:expected_output) { "2 cup flour\n4 tbsp butter" }

      it 'scales and formats each ingredient description' do
        expect(calculated_ingredients).to eq(expected_output)
      end
    end

    context 'with mixed unicode fractions and ranges' do
      let(:multiplier) { 5 }
      let(:ingredients_text) do
        <<~INGREDIENTS
          1¼ cups vinegar
          1¾ to 2 pounds cucumbers
        INGREDIENTS
      end
      let(:expected_output) { "1 9/16 qt vinegar\n8 3/4 to 10 pounds cucumbers" }

      it 'handles mixed numbers and ranges across the full pipeline' do
        expect(calculated_ingredients).to eq(expected_output)
      end
    end

    context 'with ingredients that do not have convertible units' do
      let(:multiplier) { 3 }
      let(:ingredients_text) do
        <<~INGREDIENTS
          2 eggs
          Just some text without numbers or units
        INGREDIENTS
      end
      let(:expected_output) { "6 eggs\n3 Just some text without numbers or units" }

      it 'preserves readable descriptions for non-convertible items' do
        expect(calculated_ingredients).to eq(expected_output)
      end
    end
  end
end
