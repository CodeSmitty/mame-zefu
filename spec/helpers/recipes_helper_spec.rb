require 'rails_helper'

RSpec.describe RecipesHelper do
  describe '#category_select_options' do
    subject(:options) { helper.category_select_options(recipe) }

    let(:recipe) { build(:recipe) }
    let(:category_names) { [] }
    let(:pending_category_names) { [] }
    let(:expected_options) do
      expected_categories
        .map { |name| [name, name] }
    end

    before do
      recipe.save!
      Category.from_names(category_names, user: recipe.user)
      recipe.pending_category_names = pending_category_names
    end

    context 'when there are only existing categories' do
      let(:category_names) { %w[Main Dessert] }
      let(:expected_categories) { category_names }

      it 'returns existing categories as select options' do
        expect(options).to match_array(expected_options)
      end
    end

    context 'when there are pending category names' do
      let(:pending_category_names) { %w[French Appetizer] }
      let(:expected_categories) { pending_category_names }

      it 'includes pending categories in the options' do
        expect(options).to match_array(expected_options)
      end
    end

    context 'when there are both existing and pending categories' do
      let(:category_names) { %w[Main] }
      let(:pending_category_names) { %w[French Appetizer] }
      let(:expected_categories) { (category_names + pending_category_names) }

      it 'combines existing and pending categories' do
        expect(options).to match_array(expected_options)
      end
    end

    context 'when there are duplicate category names' do
      let(:category_names) { %w[Main] }
      let(:pending_category_names) { %w[Main French] }
      let(:expected_categories) { %w[Main French] }

      it 'removes duplicates' do
        expect(options).to match_array(expected_options)
      end
    end

    context 'when there are no categories' do
      let(:expected_categories) { [] }

      it 'returns an empty array' do
        expect(options).to be_empty
      end
    end
  end
end
