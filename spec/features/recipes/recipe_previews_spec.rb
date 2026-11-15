require 'rails_helper'

RSpec.feature 'Recipe previews' do
  given(:user) { create(:user) }
  given(:url) { 'https://example.com/recipe' }
  given(:imported_recipe) do
    Recipe.new(
      name: 'Imported cake',
      ingredients: '1 cup flour',
      directions: 'Mix well',
      description: 'A cake',
      source: url,
      image_src: 'https://example.com/cake.png',
      category_names: ['Dessert']
    )
  end
  given(:import_service) { instance_double(Recipes::Import, recipe: imported_recipe) }

  background do
    allow(Recipes::Import).to receive(:new).and_return(import_service)
    allow(Recipes::Extraction).to receive(:enabled?).and_return(true)
    allow(Feature).to receive_messages(ingredient_parsing_enabled?: true, recipe_scaling_enabled?: true)
    allow(Down).to receive(:download) { Rails.root.join('spec/fixtures/files/test.png').open }
  end

  context 'when previewing a web import' do
    background do
      visit web_result_recipes_path(url:, scale: 2, as: user)
    end

    scenario 'shows an unsaved unscaled recipe' do
      expect(page).to have_text('This recipe has not been saved.')
      expect(page).to have_text('Imported cake')
      expect(page).to have_css('[itemprop="recipeIngredient"]', text: '1 c flour')
      expect(page).to have_no_css('[aria-label^="Scale recipe"]')
    end

    scenario 'shows the remote image without persisted controls' do
      expect(page).to have_no_css('[data-controller="toggle-favorite"]')
      expect(page).to have_no_field('Keep screen awake', visible: :all)
      expect(page).to have_css('img[src="https://example.com/cake.png"]', visible: :all)
      expect(user.recipes.count).to eq(0)
    end

    scenario 'returns to web search without creating a recipe' do
      click_link 'Back'

      expect(page).to have_current_path(web_search_recipes_path)
      expect(user.recipes.count).to eq(0)
    end

    scenario 'saves the imported recipe and its fields' do
      click_button 'Save', exact: true

      recipe = user.recipes.last
      expect(page).to have_current_path(recipe_path(recipe))
      expect(recipe.attributes).to include('name' => 'Imported cake', 'ingredients' => '1 cup flour', 'source' => url)
    end

    scenario 'saves the imported categories and image' do
      click_button 'Save', exact: true

      recipe = user.recipes.last
      expect(recipe.category_names).to include('Dessert')
      expect(recipe.image).to be_attached
    end

    scenario 'preserves the imported description and directions' do
      click_button 'Save', exact: true

      expect(user.recipes.last.attributes).to include('directions' => 'Mix well', 'description' => 'A cake')
    end
  end

  context 'when an imported recipe has duplicate categories' do
    background do
      imported_recipe.category_names = %w[Dessert dessert Dessert Cake]
      visit web_result_recipes_path(url:, as: user)
    end

    scenario 'saves unique categories' do
      click_button 'Save', exact: true

      expect(user.recipes.last.category_names).to contain_exactly('Dessert', 'Cake')
    end
  end

  context 'when an imported name is missing' do
    background do
      imported_recipe.name = nil
      visit web_result_recipes_path(url:, as: user)
    end

    scenario 'explains the fallback name before saving it' do
      expect(page).to have_text('No recipe name was found.')
      expect(page).to have_text('Untitled imported recipe')
      click_button 'Save', exact: true

      expect(page).to have_current_path(recipe_path(user.recipes.last))
      expect(user.recipes.last.name).to eq('Untitled imported recipe')
    end
  end

  context 'when previewing an extracted recipe' do
    given(:token) { Recipes::Extraction::ResultStore.store(user:, recipe: imported_recipe) }

    background do
      visit extraction_result_recipes_path(token:, scale: 2, as: user)
    end

    scenario 'can be refreshed without being saved' do
      visit current_url

      expect(page).to have_text('Extracted Recipe')
      expect(page).to have_text('This recipe has not been saved.')
      expect(page).to have_css('[itemprop="recipeIngredient"]', text: '1 c flour')
      expect(user.recipes.count).to eq(0)
    end

    scenario 'does not show the keep screen awake toggle' do
      expect(page).to have_no_field('Keep screen awake', visible: :all)
    end

    scenario 'returns to extraction without creating a recipe' do
      click_link 'Back'

      expect(page).to have_current_path(extraction_recipes_path)
      expect(user.recipes.count).to eq(0)
    end

    scenario 'saves and opens the recipe page' do
      click_button 'Save', exact: true

      expect(page).to have_current_path(recipe_path(user.recipes.last))
    end

    context 'when the extracted name is missing' do
      given(:token) do
        Recipes::Extraction::ResultStore.store(user:, recipe: Recipe.new(ingredients: 'Flour'))
      end

      scenario 'explains and saves the fallback name' do
        visit extraction_result_recipes_path(token:, as: user)
        expect(page).to have_text('No recipe name was found.')
        click_button 'Save', exact: true

        expect(page).to have_current_path(recipe_path(user.recipes.last))
        expect(user.recipes.last.name).to eq('Untitled extracted recipe')
      end
    end
  end

  context 'when an extracted recipe has duplicate categories' do
    given(:token) do
      imported_recipe.category_names = %w[Dessert dessert Dessert Cake]
      Recipes::Extraction::ResultStore.store(user:, recipe: imported_recipe)
    end

    background { visit extraction_result_recipes_path(token:, as: user) }

    scenario 'saves unique categories' do
      click_button 'Save', exact: true

      expect(user.recipes.last.category_names).to contain_exactly('Dessert', 'Cake')
    end
  end
end
