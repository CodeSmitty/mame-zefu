require 'rails_helper'

RSpec.feature 'User edits a recipe' do
  given(:user) { create(:user) }
  given(:home_page) { HomePage.new }
  given(:edit_recipe_page) { EditRecipePage.new }
  given(:recipe_show_page) { RecipeShowPage.new }

  given!(:recipe) { create(:recipe, user: user) }
  given(:recipe_data) do
    {
      name: 'Chocolate Chip Cookies'
    }
  end

  background do
    visit root_path(as: user)
    home_page.load
  end

  scenario 'successfully' do
    home_page.recipe_link(recipe.name).click

    recipe_show_page.edit_button.click
    edit_recipe_page.recipe_form.save_recipe(recipe_data)

    expect(home_page).to have_content('Recipe was successfully updated.')
    expect(recipe_show_page.recipe_name).to have_text(recipe_data[:name])
  end

  scenario 'and clicks cancel' do
    home_page.recipe_link(recipe.name).click

    recipe_show_page.edit_button.click
    edit_recipe_page.recipe_form.fill_form(recipe_data)
    edit_recipe_page.cancel_button.click

    expect(recipe_show_page.recipe_name).to have_text(recipe.name)
  end
end
