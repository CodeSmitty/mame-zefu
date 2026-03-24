require 'rails_helper'

RSpec.describe Recipes::YieldUpdater do
  let(:user) { create(:user) }
  let(:recipe) do
    create(
      :recipe,
      user: user,
      yield: '24 servings',
      ingredients: ingredients_text
    )
  end
  let(:ingredients_text) do
    <<~INGREDIENTS
      1 cup flour
      2 tablespoons butter
    INGREDIENTS
  end

  describe '#call' do
    context 'when the recipe update succeeds' do
      let(:params) do
        {
          new_yield: 48,
          original_yield: 24,
          base_yield: 24,
          base_ingredients: ingredients_text
        }
      end
      let(:result) { described_class.new(recipe: recipe, params: params).call }

      it 'returns a successful result with updated values' do
        expect(result.success?).to be true
        expect(result.yield_display).to eq('48 servings')
        expect(result.ingredients).to eq("2 cup flour\n4 tbsp butter")
      end

      it 'persists the changes to the database' do
        result
        recipe.reload
        expect(recipe.yield).to eq('48 servings')
        expect(recipe.ingredients).to eq("2 cup flour\n4 tbsp butter")
      end
    end

    context 'when base values are not provided' do
      let(:ingredients_text) do
        <<~INGREDIENTS
          1¼ cups vinegar
          2 cups water
        INGREDIENTS
      end
      let(:params) do
        {
          new_yield: 120,
          original_yield: 24,
          base_yield: 0,
          base_ingredients: nil
        }
      end

      it 'falls back to original_yield and recipe ingredients' do
        result = described_class.new(recipe: recipe, params: params).call

        expect(result.success?).to be true
        expect(result.yield_display).to eq('120 servings')
        expect(result.ingredients).to eq("1 9/16 qt vinegar\n2 1/2 qt water")
      end
    end

    context 'when the recipe update fails' do
      let(:params) do
        {
          new_yield: 48,
          original_yield: 24,
          base_yield: 24,
          base_ingredients: ingredients_text
        }
      end

      it 'returns an unsuccessful result' do
        allow(recipe).to receive(:update).and_return(false)

        result = described_class.new(recipe: recipe, params: params).call

        expect(result.success?).to be false
        expect(result.yield_display).to be_nil
        expect(result.ingredients).to be_nil
      end
    end
  end
end
