require 'rails_helper'

RSpec.describe Recipe do
  it { is_expected.to validate_presence_of(:name) }

  describe '#category_names' do
    subject { recipe.category_names }

    let(:recipe) { create(:recipe, name: 'Spaghetti') }
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

    let(:recipe) { create(:recipe, name: 'Spaghetti') }
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

    let(:recipes) { create_list(:recipe, 3) }

    context 'when query is an empty string' do
      let(:query) { '' }

      it { is_expected.to match_array recipes }
    end

    context 'when query is nil' do
      let(:query) { nil }

      it { is_expected.to match_array recipes }
    end

    context 'when query does not match case' do
      let(:recipe) { create(:recipe, name: 'Birria Tacos') }
      let(:query) { 'taco' }

      it { is_expected.to include recipe }
      it { is_expected.to contain_exactly recipe }
    end
  end

  describe '.in_categories' do
    subject { described_class.in_categories(category_names) }

    let!(:mexican) { create(:category, name: 'Mexican') }
    let!(:italian) { create(:category, name: 'Italian') }
    let!(:japanese) { create(:category, name: 'Japanese') }

    let!(:tacos) { create(:recipe, name: 'Tacos', categories: [mexican]) }
    let!(:pasta) { create(:recipe, name: 'Pasta', categories: [italian]) }
    let!(:sushi) { create(:recipe, name: 'Sushi', categories: [japanese]) }
    let!(:fusion) { create(:recipe, name: 'Fusion Dish', categories: [mexican, japanese]) }

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

  describe '#attach_image_from_url' do
    let!(:stub) { stub_request(:get, image_url).to_return(body: downloaded_file, status: 200) }
    let(:image_url) { 'https://example.com/test.png' }
    let(:downloaded_file) { file_fixture('test.png').read }
    let(:recipe) { build(:recipe, image_src: image_url) }

    context 'when image_src is a valid URL and no image is attached' do
      it 'downloads the image and attaches it' do
        recipe.save

        expect(stub).to have_been_requested
        expect(recipe.image).to be_attached
      end
    end

    context 'when image_src is not a valid URL' do
      let(:image_url) { 'invalid url' }

      it 'does not download or attach' do
        recipe.save

        expect(stub).not_to have_been_requested
        expect(recipe.image).not_to be_attached
      end
    end

    context 'when image is already attached' do
      let(:recipe) { create(:recipe, image_src: image_url, image: file_fixture('test.png')) }

      before do
        allow(recipe).to receive(:attach_image_from_url).and_call_original
      end

      it 'method is not called' do
        recipe.save

        expect(recipe).not_to have_received(:attach_image_from_url)
      end
    end

    context 'when image_src is blank' do
      let(:recipe) { create(:recipe, image_src: nil) }

      before do
        allow(recipe).to receive(:attach_image_from_url).and_call_original
      end

      it 'method is not called' do
        recipe.save

        expect(recipe).not_to have_received(:attach_image_from_url)
      end
    end

    context 'when download fails' do
      let!(:stub) { stub_request(:get, image_url).to_return(status: 404) }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs an error and allows recipe to save' do
        recipe.save

        expect(stub).to have_been_requested
        expect(Rails.logger).to have_received(:error)
          .with(/Failed to download image from #{image_url}:/)
        expect(recipe).to be_persisted
      end
    end
  end
end
