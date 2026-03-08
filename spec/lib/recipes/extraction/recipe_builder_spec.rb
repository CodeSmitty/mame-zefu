# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Extraction::RecipeBuilder do
  describe '.build' do
    subject(:recipe) { described_class.build(payload) }

    let(:payload) do
      {
        'name' => '  Toast  ',
        'ingredients' => [' Bread ', '', 'Butter'],
        'directions' => ['Toast', ' Spread butter '],
        'category_names' => [' Breakfast ', '', 'Quick'],
        'yield' => 2
      }
    end

    it 'returns an unsaved recipe' do
      expect(recipe).to be_a(Recipe)
      expect(recipe).not_to be_persisted
    end

    it 'normalizes scalar text fields' do
      expect(
        [recipe.name, recipe.yield, recipe.prep_time, recipe.cook_time, recipe.total_time, recipe.description]
      ).to eq(['Toast', '2', '', '', '', ''])
    end

    it 'normalizes list fields as newline text' do
      expect(recipe.ingredients).to eq("Bread\nButter")
      expect(recipe.directions).to eq("Toast\n\nSpread butter")
    end

    it 'normalizes categories' do
      expect(recipe.category_names).to eq(%w[Breakfast Quick])
    end
  end
end
