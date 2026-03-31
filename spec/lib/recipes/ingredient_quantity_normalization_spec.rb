require 'rails_helper'

RSpec.describe 'Ingredient quantity normalization and scaling' do # rubocop:disable RSpec/DescribeClass
  it 'normalizes attached unicode fractions into mixed-number rationals' do
    parsed = Recipes::IngredientParser.new(Recipe.new(ingredients: "1¼ cup flour\n2½ cups milk")).parse_ingredients

    expect(parsed[0]).to include(quantity: '5/4', unit: 'cup')
    expect(parsed[1]).to include(quantity: '5/2', unit: 'cup')
  end

  context 'with quantity ranges' do
    let(:parsed) { Recipes::IngredientParser.new(Recipe.new(ingredients: '1¾ to 2 pounds cucumbers')).parse_ingredients }
    let(:scaled) { Recipes::IngredientScaler.new.scale_ingredients(parsed, 5) }
    let(:converted) { Recipes::UnitConverter.new.converter(scaled) }

    it 'parses the range with correct quantities and unit' do
      expect(parsed[0]).to include(quantity: '7/4', quantity_max: '2/1', unit: 'pounds')
    end

    it 'scales each bound of the range' do
      expect(scaled[0]).to include(scaled_quantity: '35/4', scaled_quantity_max: '10/1')
    end

    it 'converts to a readable range description' do
      expect(converted[0][:converted_description]).to eq('8 3/4 to 10 pounds cucumbers')
    end
  end

  it 'formats exact rational conversions without lossy float approximation' do
    ingredient = [{ scaled_quantity: '55/16', unit: 'qt', ingredient: 'liquid' }]

    converted = Recipes::UnitConverter.new.converter(ingredient)

    expect(converted[0][:converted_description]).to eq('3 7/16 qt liquid')
  end
end
