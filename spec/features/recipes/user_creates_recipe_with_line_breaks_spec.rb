require 'rails_helper'

RSpec.feature 'User creates a recipe with line breaks in directions' do
  let(:user) { create(:user) }
  let(:home_page) { HomePage.new }
  let(:new_recipe_page) { NewRecipePage.new }
  let(:recipe_show_page) { RecipeShowPage.new }

  scenario 'creates recipe and verifies directions preserve line breaks' do
    recipe_data = {
      name: 'Test Recipe with Line Breaks',
      directions: "Foo\n\nBar\n\nBaz",
      ingredients: "1 cup flour\n\n2 eggs"
    }

    # Visit home page and sign in
    home_page.load
    home_page.sign_in(user.email, 'password')
    expect(home_page).to be_signed_in

    # Click New Recipe link
    home_page.click_new_recipe

    # Fill out the recipe form
    new_recipe_page.recipe_form.fill_form(recipe_data)

    # Submit the form
    new_recipe_page.recipe_form.submit_form

    # Verify we're on the recipe show page
    recipe = Recipe.last
    expect(current_path).to eq(recipe_path(recipe))

    # Verify the directions in the database contain the expected line breaks
    expect(recipe.reload.directions).to eq("Foo\n\nBar\n\nBaz")

    # Use the recipe show page methods to verify content
    expect(recipe_show_page.has_recipe_name?(recipe_data[:name])).to be true
    expect(recipe_show_page.has_ingredients?(recipe_data[:ingredients])).to be true
    expect(recipe_show_page.has_directions?(recipe_data[:directions])).to be true

    # Verify that directions are displayed with proper line breaks using the page method
    expect(recipe_show_page.has_directions_with_line_breaks?).to be true
  end
end
