require 'rails_helper'

RSpec.feature 'Returning from recipe forms', :js do
  given(:user) { create(:user) }
  given!(:recipe) { create(:recipe, user:, name: 'Saved recipe') }

  scenario 'restores the import page after navigating to create' do # rubocop:disable RSpec/ExampleLength
    page.current_window.resize_to(1200, 900)
    page.driver.browser.execute_cdp('Network.enable')
    page.driver.browser.execute_cdp('Network.setBlockedURLs', urls: ['*://cse.google.com/*'])
    visit web_search_recipes_path(as: user)
    page.execute_script(<<~JS)
      history.replaceState(null, '', '#gsc.tab=0')
    JS
    within('nav') { find("a[href='#{new_recipe_path}']").click }
    expect(page).to have_css('h1', text: 'Create your recipe')
    wait_for_back_controller
    click_link 'Back'

    expect(page).to have_current_path(web_search_recipes_path(as: user))
    expect(page).to have_css('h1', text: 'Import recipe')
    expect(page).to have_no_css('#recipe_form')
  ensure
    page.driver.browser.execute_cdp('Network.setBlockedURLs', urls: [])
    page.driver.browser.execute_cdp('Network.disable')
    page.current_window.resize_to(1400, 1400)
  end

  scenario 'returns from a new form to the actual previous page without creating a recipe' do # rubocop:disable RSpec/ExampleLength
    visit recipe_path(recipe, as: user)
    visit new_recipe_path(as: user)
    wait_for_back_controller
    fill_in 'Name', with: 'Unsaved recipe'
    click_link 'Back'

    expect(page).to have_current_path(recipe_path(recipe, as: user))
    expect(user.recipes.count).to eq(1)
  end

  scenario 'restores a Turbo-cached previous page without reloading' do # rubocop:disable RSpec/ExampleLength
    page.current_window.resize_to(1200, 900)
    visit recipes_path(as: user)
    page.execute_script('window.backNavigationMarker = true')
    within('nav') { find("a[href='#{new_recipe_path}']").click }
    wait_for_back_controller
    click_link 'Back'

    expect(page).to have_current_path(recipes_path(as: user))
    expect(page).to have_link(recipe.name)
    expect(page.evaluate_script('window.backNavigationMarker')).to be true
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  scenario 'preserves the form when navigating back between same-page history entries' do # rubocop:disable RSpec/ExampleLength
    visit new_recipe_path(as: user)
    wait_for_back_controller
    page.execute_script(<<~JS)
      history.pushState(null, '', '#section')
      window.addEventListener('popstate', () => { window.backPopReceived = true }, { once: true })
    JS
    fill_in 'Name', with: 'Unsaved recipe'
    click_link 'Back'
    Selenium::WebDriver::Wait.new(timeout: 10).until { page.evaluate_script('window.backPopReceived') }

    expect(page).to have_current_path(new_recipe_path(as: user))
    expect(page).to have_field('Name', with: 'Unsaved recipe')
  end

  scenario 'returns from an edit form to the actual previous page without saving' do # rubocop:disable RSpec/ExampleLength
    visit recipes_path(as: user)
    visit edit_recipe_path(recipe, as: user)
    wait_for_back_controller
    fill_in 'Name', with: 'Unsaved changes'
    click_link 'Back'

    expect(page).to have_current_path(recipes_path(as: user))
    expect(recipe.reload.name).to eq('Saved recipe')
  end

  scenario 'falls back to the index from the new form with no previous history entry' do # rubocop:disable RSpec/ExampleLength
    visit new_recipe_path(as: user)
    wait_for_back_controller
    page.execute_script("Object.defineProperty(window.history, 'length', { value: 1 })")
    click_link 'Back'

    expect(page).to have_current_path(recipes_path)
    expect(user.recipes.count).to eq(1)
  end

  scenario 'falls back to the recipe from the edit form with no previous history entry' do # rubocop:disable RSpec/ExampleLength
    visit edit_recipe_path(recipe, as: user)
    wait_for_back_controller
    page.execute_script("Object.defineProperty(window.history, 'length', { value: 1 })")
    click_link 'Back'

    expect(page).to have_current_path(recipe_path(recipe))
    expect(recipe.reload.name).to eq('Saved recipe')
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
