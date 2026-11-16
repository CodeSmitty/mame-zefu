require 'rails_helper'

RSpec.feature 'Admin inspects parsed ingredients', :js do
  given(:user) { create(:user, is_admin: true) }
  given(:recipe) { create(:recipe, user: user, ingredients: "1 cup flour\n2 eggs\n1 teaspoon salt") }

  background do
    allow(Feature).to receive(:ingredient_parsing_enabled?).and_return(true)
    visit recipe_path(recipe, as: user)
  end

  scenario 'shows and hides ingredient details without marking the ingredient as used' do # rubocop:disable RSpec/ExampleLength
    ingredient = find('[itemprop="recipeIngredient"]', match: :first)
    ingredient.find('.ingredient-debug-toggle').click

    expect(ingredient).to have_css('.ingredient-debug-panel', text: '1 cup flour')
    expect(ingredient[:class]).not_to include('line-through')

    ingredient.find('.ingredient-debug-toggle').click
    expect(ingredient).to have_no_css('.ingredient-debug-panel')
  end

  scenario 'checks the ingredient parsing feature once for all ingredients' do
    expect(page).to have_css('[itemprop="recipeIngredient"]', count: 3)
    expect(Feature).to have_received(:ingredient_parsing_enabled?).once
  end
end
