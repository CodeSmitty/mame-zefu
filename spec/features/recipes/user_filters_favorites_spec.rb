require 'rails_helper'

RSpec.feature 'User filters favorite recipes', :js do
  given(:user) { create(:user) }
  given!(:favorite) { create(:recipe, user: user, name: 'Favorite recipe', is_favorite: true) }
  given!(:other_recipe) { create(:recipe, user: user, name: 'Other recipe', is_favorite: false) }

  scenario 'automatically filters and restores recipes when toggled' do # rubocop:disable RSpec/ExampleLength
    visit recipes_path(as: user)

    expect(page).to have_link(other_recipe.name)

    check 'Favorites Only', allow_label_click: true

    expect(page).to have_no_link(other_recipe.name)
    expect(page).to have_link(favorite.name)

    uncheck 'Favorites Only', allow_label_click: true

    expect(page).to have_link(other_recipe.name)
  end
end
