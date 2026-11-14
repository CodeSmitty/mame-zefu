require 'rails_helper'

RSpec.feature 'User interacts with a recipe', :js do
  given(:user) { create(:user) }
  given(:recipe) do
    create(:recipe, user: user, is_favorite: false, ingredients: "1 cup flour\n2 eggs",
                    directions: "Mix ingredients\n\nBake until golden")
  end

  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  background { visit recipe_path(recipe, as: user) }

  scenario 'marks ingredients as used and unmarks them' do
    ingredient = find('[itemprop="recipeIngredient"]', text: '1 cup flour')
    ingredient.click
    expect(ingredient[:class]).to include('line-through')

    ingredient.click
    expect(ingredient[:class]).not_to include('line-through')
  end

  scenario 'focuses on one direction at a time and clears the focus' do # rubocop:disable RSpec/ExampleLength
    first_step = find('li', text: 'Mix ingredients')
    second_step = find('li', text: 'Bake until golden')
    first_step.click
    expect(first_step[:class]).to include('font-bold')

    second_step.click
    expect(first_step[:class]).not_to include('font-bold')
    expect(second_step[:class]).to include('font-bold')

    second_step.click
    expect(second_step[:class]).not_to include('font-bold')
  end

  scenario 'adds and removes a favorite without leaving the recipe' do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    button = find('button[aria-label="Add to favorites"]')
    empty_heart = button.find('svg')[:outerHTML]
    button.click

    expect(page).to have_css('[data-toggle-favorite-is-favorite-value="true"]')
    expect(button.find('svg')[:outerHTML]).not_to eq(empty_heart)
    expect(recipe.reload.is_favorite).to be(true)

    button.click
    expect(page).to have_css('[data-toggle-favorite-is-favorite-value="false"]')
    expect(recipe.reload.is_favorite).to be(false)
  end
end
