require 'rails_helper'

RSpec.feature 'Returning from a recipe', :js do
  given(:user) { create(:user) }
  given!(:recipe) { create(:recipe, user:, name: 'Current recipe') }
  given!(:previous_recipe) { create(:recipe, user:, name: 'Previous recipe') }

  scenario 'returns to the previous page from the mobile action bar' do # rubocop:disable RSpec/ExampleLength
    page.current_window.resize_to(320, 700)
    visit recipe_path(previous_recipe, as: user)
    visit recipe_path(recipe, as: user)
    wait_for_back_controller
    click_link 'Back'

    expect(page).to have_current_path(recipe_path(previous_recipe, as: user))
    expect(page).to have_css('[itemprop="name"]', text: 'Previous recipe')
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  scenario 'falls back to the index when there is no previous history entry' do # rubocop:disable RSpec/ExampleLength
    visit recipe_path(recipe, as: user)
    wait_for_back_controller
    page.execute_script("Object.defineProperty(window.history, 'length', { value: 1 })")
    click_link 'Back'

    expect(page).to have_current_path(recipes_path)
    expect(page).to have_link('Current recipe')
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

  scenario 'opens the index without JavaScript', js: false do
    visit recipe_path(recipe, as: user)
    click_link 'Back'

    expect(page).to have_current_path(recipes_path)
  end
end
