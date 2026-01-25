require 'rails_helper'

RSpec.feature 'User edits and deletes recipes' do
  let(:user) { create(:user) }
  let(:home_page) { HomePage.new }
  let(:recipe_show_page) { RecipeShowPage.new }
  let(:edit_recipe_page) { EditRecipePage.new }

  let!(:recipe) do
    create(:recipe, user: user, name: 'Original Recipe', directions: "Step 1\n\nStep 2")
  end

  before do
    home_page.load
    home_page.sign_in(user.email, 'password')
    expect(home_page).to be_signed_in
  end

  scenario 'edits a recipe successfully' do
    # Navigate to the recipe show page
    visit recipe_path(recipe)

    # Click edit button
    recipe_show_page.edit_button.click

    # Verify we're on the edit page
    expect(page).to have_current_path(edit_recipe_path(recipe), ignore_query: true)

    # Update the recipe
    updated_data = {
      name: 'Updated Recipe Name',
      directions: "Updated Step 1\n\nUpdated Step 2\n\nUpdated Step 3",
      ingredients: "1 cup flour\n\n2 eggs"
    }

    edit_recipe_page.recipe_form.fill_form(updated_data)
    edit_recipe_page.recipe_form.submit_form

    # Verify we're back on the show page
    expect(page).to have_current_path(recipe_path(recipe), ignore_query: true)

    # Verify the recipe was updated
    recipe.reload
    expect(recipe.name).to eq(updated_data[:name])
    expect(recipe.directions).to eq(updated_data[:directions])
    expect(recipe.ingredients).to eq(updated_data[:ingredients])

    # Verify the show page displays updated content
    expect(recipe_show_page.has_recipe_name?(updated_data[:name])).to be true
    expect(recipe_show_page.has_directions?(updated_data[:directions])).to be true
    expect(recipe_show_page.has_ingredients?(updated_data[:ingredients])).to be true
  end

  scenario 'cancels editing a recipe' do
    # Navigate to the recipe show page
    visit recipe_path(recipe)

    # Click edit button
    recipe_show_page.edit_button.click

    # Click cancel
    edit_recipe_page.cancel_button.click

    # Verify we're back on the show page
    expect(page).to have_current_path(recipe_path(recipe), ignore_query: true)

    # Verify the recipe was not changed
    recipe.reload
    expect(recipe.name).to eq('Original Recipe')
  end

  scenario 'deletes a recipe' do
    # Navigate to the recipe show page
    visit recipe_path(recipe)

    # Click delete button (Rack::Test doesn't support modals, so we skip confirmation)
    recipe_show_page.delete_button.click

    # Verify we're redirected to recipes index
    expect(page).to have_current_path(recipes_path, ignore_query: true)

    # Verify the recipe was deleted
    expect(Recipe.exists?(recipe.id)).to be false
  end
end
