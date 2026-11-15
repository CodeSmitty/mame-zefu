require 'rails_helper'

RSpec.feature 'User filters recipes', :js do
  given(:user) { create(:user) }
  given(:category) { create(:category, user: user, name: 'Dessert') }
  given!(:matching_recipe) { create(:recipe, user: user, name: 'Apple pie', categories: [category]) }
  given!(:other_recipe) { create(:recipe, user: user, name: 'Tomato soup') }

  background { visit recipes_path(as: user) }

  scenario 'searches without submitting the form and keeps typing after results update' do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    find('.ts-control input')
    fill_in 'query', with: 'Apple'

    expect(page).to have_no_link(other_recipe.name)
    expect(page).to have_link(matching_recipe.name)
    expect(page.evaluate_script('document.activeElement.id')).to eq('query')

    fill_in 'query', with: 'Tomato'
    expect(page).to have_link(other_recipe.name)
    expect(page).to have_no_link(matching_recipe.name)
  end

  scenario 'filters by a selected category and removes the filter' do # rubocop:disable RSpec/ExampleLength
    find('.ts-control input').fill_in with: 'Dessert'
    find('.ts-dropdown .option', text: 'Dessert').click

    expect(page).to have_no_link(other_recipe.name)
    expect(page).to have_link(matching_recipe.name)

    find('.ts-control .item .remove').click
    expect(page).to have_link(other_recipe.name)
  end
end
