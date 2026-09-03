require 'rails_helper'

RSpec.describe Ingredient::UnitFormatter, type: :service do
  describe '#call' do
    subject(:result) { described_class.new(quantity: quantity, unit: unit, scale: scale).call }

    let(:scale) { 1 }

    context 'with a volume quantity that scales up to the next unit' do
      let(:quantity) { '16/1' }
      let(:unit) { 'tbsp' }

      it 'converts to the larger unit' do
        expect(result).to have_attributes(quantity: '1/1', unit: 'c')
      end
    end

    context 'with a volume quantity that scales up multiple units' do
      let(:quantity) { '256/1' }
      let(:unit) { 'tbsp' }

      it 'converts to the largest applicable unit' do
        expect(result).to have_attributes(quantity: '1/1', unit: 'gal')
      end
    end

    context 'with a volume quantity that is already scaled to the largest unit' do
      let(:quantity) { '1/1' }
      let(:unit) { 'gal' }

      it 'stays at the largest applicable unit' do
        expect(result).to have_attributes(quantity: '1/1', unit: 'gal')
      end
    end

    context 'with a volume quantity smaller than its unit' do
      let(:quantity) { '1/8' }
      let(:unit) { 'cup' }

      it 'scales down to a smaller unit' do
        expect(result).to have_attributes(quantity: '2/1', unit: 'tbsp')
      end
    end

    context 'with a tbsp quantity that is a clean quarter, half, or three-quarter cup' do
      let(:unit) { 'tbsp' }

      [
        ['4/1', '1/4'],
        ['8/1', '1/2'],
        ['12/1', '3/4'],
        ['20/1', '5/4'],
        ['24/1', '3/2'],
        ['28/1', '7/4']
      ].each do |tbsp_quantity, cup_quantity|
        context "with #{tbsp_quantity} tbsp" do
          let(:quantity) { tbsp_quantity }

          it "converts to #{cup_quantity} c" do
            expect(result).to have_attributes(quantity: cup_quantity, unit: 'c')
          end
        end
      end
    end

    context 'with a tbsp quantity that is not a clean fraction of a cup' do
      let(:quantity) { '5/1' }
      let(:unit) { 'tbsp' }

      it 'splits into a cup amount plus an exact tbsp remainder' do
        expect(result).to have_attributes(quantity: '1/4', unit: 'c', quantity_secondary: '1/1', unit_secondary: 'tbsp')
      end
    end

    context 'with a large tbsp quantity that scales up impractically' do
      let(:quantity) { '69/1' }
      let(:unit) { 'tbsp' }

      it 'rounds to the nearest common cup fraction' do
        expect(result).to have_attributes(quantity: '13/3', unit: 'c')
      end
    end

    context 'with a tbsp quantity that is very close to a whole number of cups' do
      let(:quantity) { '50/3' }
      let(:unit) { 'tbsp' }

      it 'rounds down to the whole cup amount' do
        expect(result).to have_attributes(quantity: '1/1', unit: 'c')
      end
    end

    context 'with a tbsp quantity too impractical for a single unit' do
      let(:quantity) { '30/1' }
      let(:unit) { 'tbsp' }

      it 'splits into a cup amount plus an exact tbsp remainder' do
        expect(result).to have_attributes(quantity: '7/4', unit: 'c', quantity_secondary: '2/1', unit_secondary: 'tbsp')
      end
    end

    context 'with a tbsp quantity smaller than a whole cup' do
      let(:quantity) { '14/1' }
      let(:unit) { 'tbsp' }

      it 'splits into a cup fraction plus an exact tbsp remainder' do
        expect(result).to have_attributes(quantity: '3/4', unit: 'c', quantity_secondary: '2/1', unit_secondary: 'tbsp')
      end
    end

    context 'with a tsp quantity too impractical for a single unit' do
      let(:quantity) { '54/1' }
      let(:unit) { 'tsp' }

      it 'splits into a cup amount plus an exact tbsp remainder' do
        expect(result).to have_attributes(quantity: '1/1', unit: 'c', quantity_secondary: '2/1', unit_secondary: 'tbsp')
      end
    end

    context 'with a tsp quantity smaller than a whole cup' do
      let(:quantity) { '14/1' }
      let(:unit) { 'tsp' }

      it 'splits into a cup fraction plus an exact tsp remainder' do
        expect(result).to have_attributes(quantity: '1/4', unit: 'c', quantity_secondary: '2/1', unit_secondary: 'tsp')
      end
    end

    context 'with a compound remainder that is not a whole number of tbsp' do
      let(:quantity) { '91/1' }
      let(:unit) { 'tsp' }

      it 'splits into a cup amount plus a tsp remainder' do
        expect(result).to have_attributes(quantity: '7/4', unit: 'c', quantity_secondary: '7/1', unit_secondary: 'tsp')
      end
    end

    context 'with a tsp quantity that is a clean third cup' do
      let(:unit) { 'tsp' }

      [
        ['16/1', '1/3'],
        ['32/1', '2/3'],
        ['64/1', '4/3'],
        ['80/1', '5/3']
      ].each do |tsp_quantity, cup_quantity|
        context "with #{tsp_quantity} tsp" do
          let(:quantity) { tsp_quantity }

          it "converts to #{cup_quantity} c" do
            expect(result).to have_attributes(quantity: cup_quantity, unit: 'c')
          end
        end
      end
    end

    context 'with a tsp quantity that is not a clean fraction of a cup' do
      let(:quantity) { '5/1' }
      let(:unit) { 'tsp' }

      it 'stays in tsp' do
        expect(result).to have_attributes(quantity: '5/1', unit: 'tsp')
      end
    end

    context 'with a tsp quantity close to a quarter teaspoon' do
      let(:quantity) { '10/3' }
      let(:unit) { 'tsp' }

      it 'rounds to the nearest quarter teaspoon' do
        expect(result).to have_attributes(quantity: '13/4', unit: 'tsp')
      end
    end

    context 'with a tsp quantity too far from a quarter teaspoon to round' do
      let(:quantity) { '7/6' }
      let(:unit) { 'tsp' }

      it 'stays unrounded' do
        expect(result).to have_attributes(quantity: '7/6', unit: 'tsp')
      end
    end

    context 'with a pint quantity' do
      let(:quantity) { '1/1' }
      let(:unit) { 'pint' }

      it 'converts to cups' do
        expect(result).to have_attributes(quantity: '2/1', unit: 'c')
      end
    end

    context 'with a quart quantity' do
      let(:quantity) { '1/1' }
      let(:unit) { 'quart' }

      it 'converts to cups' do
        expect(result).to have_attributes(quantity: '4/1', unit: 'c')
      end
    end

    context 'with a metric weight quantity' do
      let(:quantity) { '1000/1' }
      let(:unit) { 'g' }

      it 'converts within the metric ladder' do
        expect(result).to have_attributes(quantity: '1/1', unit: 'kg')
      end
    end

    context 'with an imperial weight quantity' do
      let(:quantity) { '16/1' }
      let(:unit) { 'oz' }

      it 'converts within the imperial ladder' do
        expect(result).to have_attributes(quantity: '1/1', unit: 'lb')
      end
    end

    context 'with an unrecognized unit' do
      let(:quantity) { '2/1' }
      let(:unit) { 'pinch' }

      it 'returns the quantity and unit unchanged' do
        expect(result).to have_attributes(quantity: '2/1', unit: 'pinch')
      end
    end

    context 'with no unit' do
      let(:quantity) { '2/1' }
      let(:unit) { nil }

      it 'returns the quantity unchanged' do
        expect(result).to have_attributes(quantity: '2/1', unit: '')
      end
    end

    context 'with a scale multiplier' do
      let(:quantity) { '1/1' }
      let(:unit) { 'tbsp' }
      let(:scale) { '3/1' }

      it 'multiplies the quantity before converting units' do
        expect(result).to have_attributes(quantity: '3/1', unit: 'tbsp')
      end
    end

    context 'with a fractional scale multiplier and no unit' do
      let(:quantity) { '2/1' }
      let(:unit) { nil }
      let(:scale) { '1/2' }

      it 'multiplies the quantity unchanged by unit' do
        expect(result).to have_attributes(quantity: '1/1', unit: '')
      end
    end

    context 'with a quantity range' do
      subject(:range_result) { described_class.new(quantity:, quantity_max:, unit:, scale:).call }

      let(:quantity) { '1/1' }
      let(:quantity_max) { '2/1' }
      let(:unit) { 'tbsp' }
      let(:scale) { '2/1' }

      it 'returns both scaled endpoints in the selected unit' do
        expect(range_result).to have_attributes(quantity: '2/1', quantity_max: '4/1', unit: 'tbsp')
      end
    end
  end
end
