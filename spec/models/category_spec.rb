require 'rails_helper'

RSpec.describe Category do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to belong_to(:user) }

  describe '.from_names' do
    subject(:described_method) { described_class.from_names(category_names, user: user) }

    let(:user) { create(:user) }
    let(:category_names) { %w[Pasta Italian Main] }

    context 'when the categories do not exist' do
      it 'adds all of the categories' do
        expect { described_method }.to change(described_class, :count).by(3)
      end

      it { is_expected.to all be_a described_class }

      it 'returns the requested categories' do
        expect(described_method.map(&:name)).to match_array(category_names)
      end

      it 'associates all categories with the user' do
        expect(described_method.map(&:user)).to all eq(user)
      end
    end

    context 'when a category already exists for the user' do
      before { user.categories.create(name: category_names.first) }

      it 'adds the missing categories' do
        expect { described_method }.to change(described_class, :count).by(2)
      end

      it { is_expected.to all be_a described_class }

      it 'returns the requested categories' do
        expect(described_method.map(&:name)).to match_array(category_names)
      end
    end

    context 'when a category with the same name exists for a different user' do
      let(:other_user) { create(:user) }

      before { other_user.categories.create(name: category_names.first) }

      it 'creates all categories for the user' do
        expect { described_method }.to change(described_class, :count).by(3)
      end

      it 'returns the requested categories for the user' do
        categories = described_method
        expect(categories.map(&:name)).to match_array(category_names)
        expect(categories.map(&:user)).to all eq(user)
      end
    end
  end
end
