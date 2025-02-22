require 'rails_helper'

RSpec.describe Recipe, type: :model do
  it { is_expected.to validate_presence_of(:name) }

  let(:recipe) { Recipe.create(name: 'Spaghetti') }
  let(:category_names) { %w[Pasta Italian Main] }

  describe '#category_names' do
    subject { recipe.category_names }

    context 'when recipe has no categories' do
      it { is_expected.to eq [] }
    end

    context 'when recipe has categories' do
      before { recipe.categories << Category.from_names(category_names) }

      it { is_expected.to match_array(category_names) }
    end
  end

  describe '#category_names=' do
    subject { recipe.category_names = category_names }

    context 'when there are no categories' do
      it 'creates the categories' do
        expect { subject }.to change { Category.count }.by(3)
      end

      it 'adds the categories to the recipe' do
        expect { subject }.to change { recipe.categories.count }.by(3)
      end
    end

    context 'when the recipe already has categories' do
      before { recipe.categories << Category.from_names(existing_categories) }
      let(:existing_categories) { %w[Main Vegetarian] }

      it 'changes the categories to match the names exactly' do
        expect(recipe.categories.map(&:name)).to match_array(existing_categories)
        subject
        expect(recipe.categories.map(&:name)).to match_array(category_names)
      end

      context 'when given an empty array' do
        let(:category_names) { [] }

        it 'removes all categories' do
          expect { subject }.to change { recipe.categories.count }.from(2).to(0)
        end
      end
    end
  end

  describe '.search' do
    subject { Recipe.search(query) }

    let!(:recipes) do
      Array.new(3) do |i|
        Recipe.create(name: "Recipe #{i}")
      end
    end

    context 'when query is an empty string' do
      let(:query) { '' }

      it { is_expected.to match_array recipes }
    end

    context 'when query is nil' do
      let(:query) { nil }

      it { is_expected.to match_array recipes }
    end

    context 'when query does not match case' do
      let(:recipe) { Recipe.create(name: 'Birria Tacos') }
      let(:query) { 'taco' }

      it { is_expected.to include recipe }
      it { is_expected.to contain_exactly recipe }
    end
  end

  describe '.category_search' do
    it 'returns all when param is empty'
    it 'returns recipes for category'
  end
end
