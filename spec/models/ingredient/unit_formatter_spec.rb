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

    context 'with a pint quantity' do
      let(:quantity) { '2/1' }
      let(:unit) { 'cup' }

      it 'converts to pints' do
        expect(result).to have_attributes(quantity: '1/1', unit: 'pt')
      end
    end

    context 'with a volume quantity that scales up multiple units' do
      let(:quantity) { '1/1' }
      let(:unit) { 'gal' }

      it 'stays at the largest applicable unit' do
        expect(result).to have_attributes(quantity: '1/1', unit: 'gal')
      end
    end

    context 'with a volume quantity smaller than one of its unit' do
      let(:quantity) { '1/5' }
      let(:unit) { 'cup' }

      it 'scales down to a smaller unit' do
        expect(result).to have_attributes(quantity: '16/5', unit: 'tbsp')
      end
    end

    context 'with a tbsp quantity that is a clean quarter, half, or three-quarter cup' do
      let(:unit) { 'tbsp' }

      [
        ['4/1', '1/4'],
        ['8/1', '1/2'],
        ['12/1', '3/4']
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

      it 'stays in tbsp' do
        expect(result).to have_attributes(quantity: '5/1', unit: 'tbsp')
      end
    end

    context 'with a tsp quantity that is a clean third cup' do
      let(:quantity) { '16/1' }
      let(:unit) { 'tsp' }

      it 'converts to 1/3 c' do
        expect(result).to have_attributes(quantity: '1/3', unit: 'c')
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
