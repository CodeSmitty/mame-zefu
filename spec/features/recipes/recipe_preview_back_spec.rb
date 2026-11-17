require 'rails_helper'

RSpec.feature 'Returning from recipe previews', :js do
  given(:user) { create(:user) }
  given(:imported_recipe) { Recipe.new(name: 'Imported cake') }
  given(:import_service) { instance_double(Recipes::Import, recipe: imported_recipe) }
  given(:token) { Recipes::Extraction::ResultStore.store(user:, recipe: imported_recipe) }

  background do
    allow(Recipes::Import).to receive(:new).and_return(import_service)
    allow(Recipes::Extraction).to receive(:enabled?).and_return(true)
  end

  scenario 'returns to the actual previous page from a web import' do # rubocop:disable RSpec/ExampleLength
    visit recipes_path(as: user)
    visit web_result_recipes_path(url: 'https://example.com/recipe', as: user)
    wait_for_back_controller
    click_link 'Back'

    expect(page).to have_current_path(recipes_path(as: user))
    expect(user.recipes.count).to eq(0)
  end

  scenario 'returns to the actual previous page from an extraction preview' do # rubocop:disable RSpec/ExampleLength
    visit recipes_path(as: user)
    visit extraction_result_recipes_path(token:, as: user)
    wait_for_back_controller
    click_link 'Back'

    expect(page).to have_current_path(recipes_path(as: user))
    expect(user.recipes.count).to eq(0)
  end

  scenario 'uses the web search fallback when there is no previous history entry' do # rubocop:disable RSpec/ExampleLength
    visit web_result_recipes_path(url: 'https://example.com/recipe', as: user)
    wait_for_back_controller
    page.execute_script("Object.defineProperty(window.history, 'length', { value: 1 })")
    click_link 'Back'

    expect(page).to have_current_path(web_search_recipes_path)
    expect(user.recipes.count).to eq(0)
  end

  scenario 'uses the extraction fallback when there is no previous history entry' do # rubocop:disable RSpec/ExampleLength
    visit extraction_result_recipes_path(token:, as: user)
    wait_for_back_controller
    page.execute_script("Object.defineProperty(window.history, 'length', { value: 1 })")
    click_link 'Back'

    expect(page).to have_current_path(extraction_recipes_path)
    expect(user.recipes.count).to eq(0)
  end

  def wait_for_back_controller
    Selenium::WebDriver::Wait.new(timeout: 10).until do
      page.evaluate_script(<<~JS)
        !!window.Stimulus?.getControllerForElementAndIdentifier(
          document.querySelector('[data-controller="history-back"]'), 'history-back'
        )
      JS
    end
  end
end
