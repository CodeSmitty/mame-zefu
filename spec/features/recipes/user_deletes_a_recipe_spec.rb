require 'rails_helper'

RSpec.feature 'User deletes a recipe' do
  given(:user) { create(:user) }
  given(:home_page) { HomePage.new }
  given(:recipe_show_page) { RecipeShowPage.new }

  given!(:recipe) { create(:recipe, user: user) }

  background do
    visit root_path(as: user)
    home_page.load
  end

  scenario 'successfully' do
    home_page.recipe_link(recipe.name).click

    recipe_show_page.delete_button.click

    expect(home_page).to have_content('Recipe was successfully destroyed.')
    expect(home_page).to have_no_link(recipe.name)
  end
end
