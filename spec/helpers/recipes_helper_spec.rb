require 'rails_helper'

RSpec.describe RecipesHelper do
  describe '#recipe_extraction_enabled?' do
    let(:current_user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    it 'delegates to Recipes::Extraction.enabled?' do
      allow(Recipes::Extraction).to receive(:enabled?).and_return(true)

      expect(helper.recipe_extraction_enabled?).to be(true)
      expect(Recipes::Extraction).to have_received(:enabled?).with(current_user)
    end
  end

  describe '#ingredient_parsing_enabled?' do
    let(:current_user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    it 'delegates to Feature.ingredient_parsing_enabled?' do
      allow(Feature).to receive(:ingredient_parsing_enabled?).and_return(true)

      expect(helper.ingredient_parsing_enabled?).to be(true)
      expect(Feature).to have_received(:ingredient_parsing_enabled?).with(current_user)
    end
  end

  describe '#recipe_scaling_enabled?' do
    let(:current_user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    it 'delegates to Feature.recipe_scaling_enabled?' do
      allow(Feature).to receive(:recipe_scaling_enabled?).and_return(true)

      expect(helper.recipe_scaling_enabled?).to be(true)
      expect(Feature).to have_received(:recipe_scaling_enabled?).with(current_user)
    end
  end

  describe '#current_recipe_scale' do
    subject(:scale) { helper.current_recipe_scale }

    before do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(scale: scale_param))
    end

    context 'when no scale param is present' do
      let(:scale_param) { nil }

      it { is_expected.to eq(1) }
    end

    context 'when the scale param is 1' do
      let(:scale_param) { '1' }

      it { is_expected.to eq(1) }
    end

    context 'when the scale param is a positive even whole number' do
      let(:scale_param) { '4' }

      it { is_expected.to eq(4) }
    end

    context 'when the scale param is a positive odd number other than 1' do
      let(:scale_param) { '3' }

      it { is_expected.to eq(1) }
    end

    context 'when the scale param is not a whole number' do
      let(:scale_param) { '2.5' }

      it { is_expected.to eq(1) }
    end

    context 'when the scale param is not positive' do
      let(:scale_param) { '-2' }

      it { is_expected.to eq(1) }
    end
  end

  describe '#previous_recipe_scale' do
    subject(:scale) { helper.previous_recipe_scale }

    context 'when the current scale is 1' do
      before { allow(helper).to receive(:current_recipe_scale).and_return(1) }

      it { is_expected.to be_nil }
    end

    context 'when the current scale is 2' do
      before { allow(helper).to receive(:current_recipe_scale).and_return(2) }

      it { is_expected.to eq(1) }
    end

    context 'when the current scale is greater than 2' do
      before { allow(helper).to receive(:current_recipe_scale).and_return(6) }

      it { is_expected.to eq(4) }
    end
  end

  describe '#next_recipe_scale' do
    subject(:scale) { helper.next_recipe_scale }

    context 'when the current scale is 1' do
      before { allow(helper).to receive(:current_recipe_scale).and_return(1) }

      it { is_expected.to eq(2) }
    end

    context 'when the current scale is greater than 1' do
      before { allow(helper).to receive(:current_recipe_scale).and_return(4) }

      it { is_expected.to eq(6) }
    end
  end

  describe '#parsed_ingredient_markup' do
    subject(:markup) { helper.parsed_ingredient_markup('1 cup flour') }

    let(:current_user) { build_stubbed(:user, is_admin: is_admin) }
    let(:is_admin) { false }

    before do
      allow(helper).to receive_messages(current_user: current_user, ingredient_parsing_enabled?: feature_enabled)
    end

    context 'when ingredient parsing is enabled' do
      let(:feature_enabled) { true }

      it 'renders parsed quantity, unit, and ingredient markup' do
        expect(markup).to include('1', 'c', 'flour')
      end

      it 'does not include a debug toggle for non-admin users' do
        expect(markup).not_to include('ingredient-debug-toggle')
      end

      context 'when the current user is an admin' do
        let(:is_admin) { true }

        it 'includes a debug toggle button' do
          expect(markup).to include('ingredient-debug-toggle')
        end

        it 'includes the parsed ingredient but omits an unchanged rounded measurement' do
          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).to include('"original": "1 cup flour"', '"parsed": {',
                                            '"quantity": "1/1"', '"unit": "cup"', '"name": "flour"')
          expect(decoded_markup).not_to include('"rounded": {')
        end

        it 'includes the best-fit ingredient' do
          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).to include('"best_fit": {', '"quantity": "1/1"', '"unit": "cup"')
        end

        it 'omits the scaled attributes when no scale is applied' do
          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).not_to include('"scaled": {')
        end
      end

      context 'when parser returns an invalid quantity value' do
        let(:parser_double) do
          instance_double(
            Ingredient::Parser,
            parse: Ingredient.new(quantity: 'bogus', unit: 'cup', name: 'flour')
          )
        end

        before do
          allow(Ingredient::Parser).to receive(:new).and_return(parser_double)
        end

        it 'renders the original quantity text through the public helper API' do
          expect(markup).to include('bogus', 'cup', 'flour')
        end
      end

      context 'when the ingredient has a quantity but no unit' do
        subject(:markup) { helper.parsed_ingredient_markup('2 eggs') }

        before do
          allow(helper).to receive(:current_user).and_return(build_stubbed(:user, is_admin: true))
        end

        it 'renders without attempting unit conversion for the rounded debug data' do
          expect { markup }.not_to raise_error
        end
      end

      context 'when parser returns a quantity range' do
        let(:parser_double) do
          instance_double(
            Ingredient::Parser,
            parse: Ingredient.new(quantity: '1/1', quantity_max: '2/1', unit: 'tsp', name: 'sugar')
          )
        end

        before do
          allow(Ingredient::Parser).to receive(:new).and_return(parser_double)
        end

        it 'renders both minimum and maximum quantities' do
          expect(markup).to include('1 to 2', 'tsp', 'sugar')
        end
      end

      context 'when the quantity converts to a larger unit' do
        subject(:markup) { helper.parsed_ingredient_markup('6 teaspoon salt') }

        it 'renders the converted quantity and unit' do
          expect(markup).to include('2', 'tbsp', 'salt')
        end
      end

      context 'when the quantity is too impractical for a single unit' do
        subject(:markup) { helper.parsed_ingredient_markup('30 tablespoon butter') }

        before do
          allow(helper).to receive(:current_user).and_return(build_stubbed(:user, is_admin: true))
        end

        it 'renders the compound measurement' do
          expect(markup).to include('1 3/4', 'c', '+ 2 tbsp', 'butter')
        end

        it 'omits rounded data because the compound best fit is exact' do
          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).not_to include('"rounded": {')
        end

        it 'shows the compound quantity in the best-fit debug data' do
          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).to include('"best_fit": {', '"quantity": "7/4"', '"unit": "c"',
                                            '"quantity_secondary": "2/1"', '"unit_secondary": "tbsp"')
        end
      end

      context 'when a scale param is present' do
        before do
          allow(helper).to receive(:params).and_return(ActionController::Parameters.new(scale: '2'))
        end

        it 'scales the ingredient quantity' do
          expect(markup).to include('2', 'c', 'flour')
        end

        it 'omits rounded data when scaling changes the amount but not through rounding' do
          allow(helper).to receive(:current_user).and_return(build_stubbed(:user, is_admin: true))

          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).not_to include('"rounded": {')
        end

        it 'shows the scale value above the scaled attributes' do
          allow(helper).to receive(:current_user).and_return(build_stubbed(:user, is_admin: true))

          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).to include('"scale": "2"')
          expect(decoded_markup.index('"scale":')).to be < decoded_markup.index('"scaled":')
        end
      end

      context 'when best-fit formatting rounds the scaled quantity' do
        subject(:markup) { helper.parsed_ingredient_markup('46 teaspoon salt') }

        before do
          allow(helper).to receive(:current_user).and_return(build_stubbed(:user, is_admin: true))
        end

        it 'shows the rounded quantity in the parsed unit' do
          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).to include('"rounded": {', '"quantity": "48/1"', '"unit": "teaspoon"')
        end

        it 'omits the redundant name from the rounded and best-fit data' do
          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup.scan('"name"').size).to eq(1)
        end
      end

      context 'when the scale param is explicitly 1' do
        before do
          allow(helper).to receive_messages(
            params: ActionController::Parameters.new(scale: '1'),
            current_user: build_stubbed(:user, is_admin: true)
          )
        end

        it 'omits the scaled attributes since they would match parsed' do
          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).not_to include('"scaled": {')
        end

        it 'omits the scale value since no scaling was applied' do
          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).not_to include('"scale":')
        end
      end

      context 'when scaling produces a compound measurement' do
        subject(:markup) { helper.parsed_ingredient_markup('15 tablespoon butter') }

        before do
          allow(helper).to receive_messages(
            params: ActionController::Parameters.new(scale: '2'),
            current_user: build_stubbed(:user, is_admin: true)
          )
        end

        it 'shows the unconverted scaled quantity separately from the final best-fit result' do
          decoded_markup = CGI.unescapeHTML(markup)

          expect(decoded_markup).to include('"scaled": {', '"quantity": "30/1"', '"unit": "tablespoon"')
          expect(markup).to include('1 3/4', 'c', '+ 2 tbsp', 'butter')
        end
      end

      context 'when the scale param is invalid' do
        before do
          allow(helper).to receive(:params).and_return(ActionController::Parameters.new(scale: 'bogus'))
        end

        it 'falls back to a scale of 1' do
          expect(markup).to include('1', 'c', 'flour')
        end
      end
    end

    context 'when ingredient parsing is disabled' do
      let(:feature_enabled) { false }

      it 'returns the original item text' do
        expect(markup).to eq('1 cup flour')
      end
    end
  end

  describe '#recipe_draft_key' do
    let(:current_user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context 'when recipe is persisted' do
      let(:recipe) { create(:recipe, user: current_user) }

      it 'returns a key with the persisted recipe id' do
        expect(helper.recipe_draft_key(recipe)).to eq("user:#{current_user.id}:recipe:#{recipe.id}")
      end
    end

    context 'when recipe is not persisted' do
      let(:recipe) { build(:recipe, user: current_user) }

      it 'returns a key with new as the recipe id' do
        expect(helper.recipe_draft_key(recipe)).to eq("user:#{current_user.id}:recipe:new")
      end
    end
  end

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
      let(:expected_categories) { category_names + pending_category_names }

      it 'combines existing and pending categories' do
        expect(options).to match_array(expected_options)
      end
    end

    context 'when categories are out of order' do
      let(:category_names) { %w[Dessert Appetizer] }
      let(:pending_category_names) { %w[Entree] }
      let(:expected_categories) { %w[Appetizer Dessert Entree] }

      it 'returns categories sorted by name' do
        expect(options).to eq(expected_options)
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

    context 'when category names have mixed case' do
      let(:category_names) { %w[banana Apple] }
      let(:expected_categories) { %w[Apple banana] }

      it 'sorts case-insensitively' do
        expect(options).to eq(expected_options)
      end
    end

    context 'when there are no categories' do
      let(:expected_categories) { [] }

      it 'returns an empty array' do
        expect(options).to be_empty
      end
    end
  end

  describe '#category_filter_options' do
    subject(:options) { helper.category_filter_options }

    let(:user) { create(:user) }
    let(:category_names) { [] }
    let(:expected_options) do
      expected_categories
        .map { |name| [name, name] }
    end

    before do
      allow(helper).to receive(:current_user).and_return(user)
      Category.from_names(category_names, user:)
    end

    context 'when there are existing categories' do
      let(:category_names) { %w[Main Dessert] }
      let(:expected_categories) { category_names }

      it 'returns category options for the current user' do
        expect(options).to match_array(expected_options)
      end
    end

    context 'when categories are out of order' do
      let(:category_names) { %w[Dessert Appetizer] }
      let(:expected_categories) { %w[Appetizer Dessert] }

      it 'returns categories sorted by name' do
        expect(options).to eq(expected_options)
      end
    end

    context 'when category names have mixed case' do
      let(:category_names) { %w[banana Apple] }
      let(:expected_categories) { %w[Apple banana] }

      it 'sorts case-insensitively' do
        expect(options).to eq(expected_options)
      end
    end

    context 'when there are duplicate category names by case' do
      let(:category_names) { %w[Main main] }
      let(:expected_categories) { %w[Main] }

      it 'removes duplicates case-insensitively' do
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
