require 'rails_helper'

RSpec.describe Category, type: :model do
  it { is_expected.to validate_presence_of(:name) }

  describe '.from_names' do
    subject { Category.from_names(category_names) }

    let(:category_names) { %w[Pasta Italian Main] }

    context 'when the categories do not exist' do
      it 'creates them' do
        expect { subject }.to change { Category.count }.by(3)
      end

      it 'returns them' do
        expect(subject).to all(be_a(Category))
        expect(subject.map(&:name)).to match_array(category_names)
      end
    end

    context 'when a category already exists' do
      before { Category.create(name: category_names.first) }

      it 'only creates what is needed' do
        expect { subject }.to change { Category.count }.by(2)
      end

      it 'returns them' do
        expect(subject).to all(be_a(Category))
        expect(subject.map(&:name)).to match_array(category_names)
      end
    end
  end
end
