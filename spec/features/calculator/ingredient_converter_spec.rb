require 'rails_helper'

RSpec.describe 'Ingredient Converter' do
  let(:unit_converter) { Recipes::UnitConverter.new }

  describe '#converter' do
    subject(:converted_result) { unit_converter.converter(scaled_ingredients) }

    let(:scaled_ingredients) do
      [
        { scaled_quantity: '2/1', unit: 'cup', ingredient: 'flour' },
        { scaled_quantity: '4/1', unit: 'tablespoons', ingredient: 'butter' },
        { scaled_quantity: '1/1', unit: 'pinch', ingredient: 'salt' },
        { scaled_quantity: '4/1', unit: 'cup', ingredient: 'milk' },
        { scaled_quantity: '16/1', unit: 'oz', ingredient: 'creamer' },
        { scaled_quantity: '6/1', unit: 'cup', ingredient: 'olive oil' }
      ]
    end

    it 'converts the units to the best fit and updates the description' do
      results = converted_result

      expect(results[0][:converted_quantity]).to eq '1'
      expect(results[0][:converted_unit]).to eq 'pt'
      expect(results[0][:converted_description]).to eq '1 pt flour'
    end

    it 'sorts volume units correctly' do
      results = converted_result
      expect(results[1][:converted_quantity]).to eq '4'
      expect(results[1][:converted_unit]).to eq 'tbsp'
      expect(results[1][:converted_description]).to eq '4 tbsp butter'
    end

    it 'sorts weight units correctly' do
      results = converted_result
      expect(results[4][:converted_quantity]).to eq '1'
      expect(results[4][:converted_unit]).to eq 'lb'
      expect(results[4][:converted_description]).to eq '1 lb creamer'
    end

    it 'handles unconvertable ingredients gracefully' do
      result = converted_result
      expect(result[2][:converted_quantity]).to eq '1'
      expect(result[2][:converted_unit]).to be_nil
      expect(result[2][:converted_description]).to eq '1 salt'
    end

    it 'handles fractional quantities correctly' do
      result = converted_result
      expect(result[5][:converted_quantity]).to eq '1 1/2'
      expect(result[5][:converted_unit]).to eq 'qt'
      expect(result[5][:converted_description]).to eq '1 1/2 qt olive oil'
    end

    it 'handles quantities that convert to whole numbers' do
      result = converted_result
      expect(result[4][:converted_quantity]).to eq '1'
      expect(result[4][:converted_unit]).to eq 'lb'
      expect(result[4][:converted_description]).to eq '1 lb creamer'
    end
  end

  describe '#find_best_unit' do
    let(:converter) { instance_double(Recipes::Volume, unit: instance_double(Measured::Unit, name: 'tsp'), value: 3) }
    let(:sorted_units) { %w[tsp tbsp cup] }

    it 'returns the original unit if no better fit is found' do
      converter = instance_double(Recipes::Volume, unit: instance_double(Measured::Unit, name: 'cup'), value: 0.5)
      result = unit_converter.send(:find_best_unit, converter, sorted_units)
      expect(result.unit.name.to_s).to eq 'cup'
      expect(result.value).to eq 0.5
    end
  end

  describe '#update_ingredient_with_conversion' do
    let(:ingredient) { { ingredient: 'flour' } }
    let(:base_unit) { instance_double(Measured::Unit, name: 'cup') }
    let(:converter) { instance_double(Recipes::Volume, value: 1.5, unit: base_unit) }

    it 'updates the ingredient with the converted quantity and unit' do
      unit_converter.send(:update_conversion, ingredient, converter)
      expect(ingredient[:converted_quantity]).to eq '1 1/2'
      expect(ingredient[:converted_unit]).to eq 'cup'
      expect(ingredient[:converted_description]).to eq '1 1/2 cup flour'
    end

    it 'handles nil converted unit correctly' do
      converter = instance_double(Recipes::Volume, value: 1.5, unit: nil)
      unit_converter.send(:update_conversion, ingredient, converter)
      expect(ingredient[:converted_quantity]).to eq '1 1/2'
      expect(ingredient[:converted_unit]).to be_nil
      expect(ingredient[:converted_description]).to eq '1 1/2 flour'
    end
  end
end
