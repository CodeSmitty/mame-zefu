require 'rails_helper'

RSpec.describe Ingredient::FractionNormalizer, type: :service do
  describe '.normalize' do
    subject(:normalized_text) { described_class.normalize(input_text) }

    context 'with a standalone unicode fraction' do
      let(:input_text) { '½ cup sugar' }

      it 'converts it to a slash fraction' do
        expect(normalized_text).to eq('1/2 cup sugar')
      end
    end

    context 'with an attached unicode fraction' do
      let(:input_text) { '1¼ cups flour' }

      it 'converts it to an improper fraction' do
        expect(normalized_text).to eq('5/4 cups flour')
      end
    end

    context 'with a mixed number using a space' do
      let(:input_text) { '2 1/2 cups milk' }

      it 'converts it to an improper fraction' do
        expect(normalized_text).to eq('5/2 cups milk')
      end
    end

    context 'with a mixed number using a dash' do
      let(:input_text) { '2-1/2 cups milk' }

      it 'converts it to an improper fraction' do
        expect(normalized_text).to eq('5/2 cups milk')
      end
    end

    context 'without fractions to normalize' do
      let(:input_text) { '3 tablespoons olive oil' }

      it 'returns the original text' do
        expect(normalized_text).to eq('3 tablespoons olive oil')
      end
    end
  end
end
