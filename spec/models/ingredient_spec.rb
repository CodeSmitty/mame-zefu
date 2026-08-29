require 'rails_helper'

RSpec.describe Ingredient do
  describe '#description' do
    subject(:description) { ingredient.description }

    context 'when the ingredient has no quantity' do
      let(:ingredient) { described_class.new(name: 'fresh oregano leaves') }

      it 'returns the ingredient name' do
        expect(description).to eq('fresh oregano leaves')
      end
    end

    context 'when the ingredient has a single quantity and unit' do
      let(:ingredient) { described_class.new(quantity: '3/2', unit: 'cup', name: 'flour') }

      it 'humanizes the quantity and includes the unit and name' do
        expect(description).to eq('1 1/2 c flour')
      end
    end

    context 'when the ingredient has a quantity but no unit' do
      let(:ingredient) { described_class.new(quantity: '2/1', name: 'eggs') }

      it 'omits the unit' do
        expect(description).to eq('2 eggs')
      end
    end

    context 'when the ingredient has a quantity range' do
      let(:ingredient) { described_class.new(quantity: '1/1', quantity_max: '2/1', unit: 'tsp', name: 'sugar') }

      it 'renders both ends of the range' do
        expect(description).to eq('1 to 2 tsp sugar')
      end
    end

    context 'when the quantity converts to a larger display unit' do
      let(:ingredient) { described_class.new(quantity: '16/1', unit: 'tbsp', name: 'butter') }

      it 'uses the best-fitting unit' do
        expect(description).to eq('1 c butter')
      end
    end
  end

  describe '#formatted_quantity' do
    subject(:formatted_quantity) { ingredient.formatted_quantity }

    context 'when the ingredient has no quantity' do
      let(:ingredient) { described_class.new(name: 'fresh oregano leaves') }

      it 'returns nil' do
        expect(formatted_quantity).to be_nil
      end
    end

    context 'when the ingredient has a single quantity' do
      let(:ingredient) { described_class.new(quantity: '3/2') }

      it 'returns a humanized quantity' do
        expect(formatted_quantity).to eq('1 1/2')
      end
    end

    context 'when the quantity converts to a larger unit' do
      let(:ingredient) { described_class.new(quantity: '6/1', unit: 'teaspoon') }

      it 'returns the converted and humanized quantity' do
        expect(formatted_quantity).to eq('2')
      end
    end

    context 'when the ingredient has a quantity range' do
      let(:ingredient) { described_class.new(quantity: '1/2', quantity_max: '3/2') }

      it 'returns both humanized quantities' do
        expect(formatted_quantity).to eq('1/2 to 1 1/2')
      end
    end
  end

  describe '#formatted_unit' do
    subject(:formatted_unit) { ingredient.formatted_unit }

    context 'when the ingredient has a unit but no quantity' do
      let(:ingredient) { described_class.new(unit: 'tsp', name: 'fresh oregano leaves') }

      it 'returns nil' do
        expect(formatted_unit).to be_nil
      end
    end

    context 'when the ingredient has no quantity and no unit' do
      let(:ingredient) { described_class.new(name: 'fresh oregano leaves') }

      it 'returns nil' do
        expect(formatted_unit).to be_nil
      end
    end

    context 'when the quantity converts to a larger unit' do
      let(:ingredient) { described_class.new(quantity: '6/1', unit: 'teaspoon') }

      it 'returns the converted unit' do
        expect(formatted_unit).to eq('tbsp')
      end
    end

    context 'when the ingredient has a quantity range' do
      let(:ingredient) { described_class.new(quantity: '1/1', quantity_max: '2/1', unit: 'tsp') }

      it 'preserves the parsed unit' do
        expect(formatted_unit).to eq('tsp')
      end
    end
  end

  describe '#scalable?' do
    it 'is true when a quantity is present' do
      expect(described_class.new(quantity: '1/1')).to be_scalable
    end

    it 'is true when a unit is present' do
      expect(described_class.new(unit: 'tsp')).to be_scalable
    end

    it 'is false when there is no quantity or unit' do
      expect(described_class.new(name: 'salt')).not_to be_scalable
    end
  end

  describe '#scale' do
    subject(:scale) { ingredient.scale(multiplier) }

    let(:ingredient) { described_class.new(quantity: '1/1', unit: 'tbsp', name: 'butter') }
    let(:multiplier) { '3/1' }

    it 'updates the quantity and unit using UnitFormatter' do
      expect(scale).to have_attributes(quantity: '3/1', unit: 'tbsp')
    end

    it 'returns the ingredient' do
      expect(scale).to be(ingredient)
    end

    context 'when the ingredient has a quantity range' do
      let(:ingredient) { described_class.new(quantity: '1/1', quantity_max: '2/1', unit: 'tbsp') }
      let(:multiplier) { '2/1' }

      it 'updates both endpoints in the formatter-selected unit' do
        expect(scale).to have_attributes(quantity: '2/1', quantity_max: '4/1', unit: 'tbsp')
      end
    end

    context 'when the ingredient has a unit but no quantity' do
      let(:ingredient) { described_class.new(unit: 'tsp', name: 'salt') }

      it 'scales assuming an original quantity of 1' do
        expect(scale.description).to eq('1 tbsp salt')
      end
    end

    context 'when the ingredient has no quantity or unit' do
      let(:ingredient) { described_class.new(name: 'salt') }

      it 'leaves the ingredient unchanged' do
        expect { scale }.not_to change(ingredient, :attributes)
      end
    end
  end

  describe '#quantity_range?' do
    it 'is true when a quantity_max is present' do
      expect(described_class.new(quantity_max: '2/1')).to be_quantity_range
    end

    it 'is false when there is no quantity_max' do
      expect(described_class.new).not_to be_quantity_range
    end
  end
end
