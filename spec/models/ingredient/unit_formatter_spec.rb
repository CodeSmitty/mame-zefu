require 'rails_helper'

RSpec.describe Ingredient::UnitFormatter, type: :service do
  describe '#call' do
    subject(:result) { described_class.new(quantity: quantity, unit: unit).call }

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
      let(:quantity) { '1/2' }
      let(:unit) { 'cup' }

      it 'scales down to a smaller unit' do
        expect(result).to have_attributes(quantity: '8/1', unit: 'tbsp')
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
  end
end
