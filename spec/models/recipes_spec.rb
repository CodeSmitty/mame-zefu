require 'rails_helper'

RSpec.describe Recipe do
  it { is_expected.to validate_presence_of(:name) }

  describe '#category_names' do
    subject { recipe.category_names }

    let(:recipe) { described_class.create(name: 'Spaghetti') }
    let(:category_names) { %w[Pasta Italian Main] }

    context 'when recipe has no categories' do
      it { is_expected.to eq [] }
    end

    context 'when recipe has categories' do
      before { recipe.categories << Category.from_names(category_names) }

      it { is_expected.to match_array(category_names) }
    end
  end

  describe '#category_names=' do
    subject(:described_method) { recipe.category_names = category_names }

    let(:recipe) { described_class.create(name: 'Spaghetti') }
    let(:category_names) { %w[Pasta Italian Main] }

    context 'when there are no categories' do
      it 'creates the categories' do
        expect { described_method }.to change(Category, :count).by(3)
      end

      it 'adds the categories to the recipe' do
        expect { described_method }.to change { recipe.categories.count }.by(3)
      end
    end

    context 'when the recipe already has categories' do
      before { recipe.categories << Category.from_names(existing_categories) }

      let(:existing_categories) { %w[Main Vegetarian] }

      it 'changes the categories to match the names exactly' do
        expect { described_method }
          .to change { recipe.categories.map(&:name) }
          .from(match_array(existing_categories))
          .to match_array(category_names)
      end

      context 'when given an empty array' do
        let(:category_names) { [] }

        it 'removes all categories' do
          expect { described_method }.to change { recipe.categories.count }.from(2).to(0)
        end
      end
    end
  end

  describe '.with_text' do
    subject { described_class.with_text(query) }

    let!(:recipes) do
      Array.new(3) do |i|
        described_class.create(name: "Recipe #{i}")
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
      let(:recipe) { described_class.create(name: 'Birria Tacos') }
      let(:query) { 'taco' }

      it { is_expected.to include recipe }
      it { is_expected.to contain_exactly recipe }
    end
  end

  describe '.in_categories' do
    subject { described_class.in_categories(category_names) }

    let!(:mexican) { Category.create!(name: 'Mexican') }
    let!(:italian) { Category.create!(name: 'Italian') }
    let!(:japanese) { Category.create!(name: 'Japanese') }

    let!(:tacos) { described_class.create!(name: 'Tacos', categories: [mexican]) }
    let!(:pasta) { described_class.create!(name: 'Pasta', categories: [italian]) }
    let!(:sushi) { described_class.create!(name: 'Sushi', categories: [japanese]) }
    let!(:fusion) { described_class.create!(name: 'Fusion Dish', categories: [mexican, japanese]) }

    context 'when category_names is empty' do
      let(:category_names) { '' }

      it { is_expected.to contain_exactly(tacos, pasta, sushi, fusion) }
    end

    context 'when category_names is nil' do
      let(:category_names) { nil }

      it { is_expected.to contain_exactly(tacos, pasta, sushi, fusion) }
    end

    context 'when passing category that matches one recipe' do
      let(:category_names) { [italian.name] }

      it { is_expected.to contain_exactly pasta }
    end

    context 'when category has no recipes' do
      let(:category_names) { ['french'] }

      it { is_expected.to match_array [] }
    end

    context 'when multiple categories match a recipe' do
      let(:category_names) { [mexican.name, japanese.name] }

      it { is_expected.to contain_exactly fusion }
    end
  end
end
