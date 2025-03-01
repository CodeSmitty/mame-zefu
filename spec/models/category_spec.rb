require 'rails_helper'

RSpec.describe Category, type: :model do
  it { is_expected.to validate_presence_of(:name) }

  describe '.from_names' do
    subject(:described_method) { described_class.from_names(category_names) }

    let(:category_names) { %w[Pasta Italian Main] }

    context 'when the categories do not exist' do
      it 'adds all of the categories' do
        expect { described_method }.to change(described_class, :count).by(3)
      end

      it { is_expected.to all be_a described_class }

      it 'returns the requested categories' do
        expect(described_method.map(&:name)).to match_array(category_names)
      end
    end

    context 'when a category already exists' do
      before { described_class.create(name: category_names.first) }

      it 'adds the missing categories' do
        expect { described_method }.to change(described_class, :count).by(2)
      end

      it { is_expected.to all be_a described_class }

      it 'returns the requested categories' do
        expect(described_method.map(&:name)).to match_array(category_names)
      end
    end
  end
end
