require 'rails_helper'

RSpec.feature 'User keeps the screen awake', :js do
  given(:user) { create(:user) }
  given(:recipe) { create(:recipe, user: user) }

  given(:wake_lock_script) do
    page.driver.browser.execute_cdp(
      'Page.addScriptToEvaluateOnNewDocument',
      source: <<~JS
        Object.defineProperty(navigator, "wakeLock", {
          configurable: true,
          value: { request: async () => ({ release: async () => {} }) }
        });
      JS
    )
  end

  background do
    wake_lock_script
    visit recipe_path(recipe, as: user)
  end

  after do
    page.execute_script('localStorage.removeItem("wakeLock")')
    page.driver.browser.execute_cdp(
      'Page.removeScriptToEvaluateOnNewDocument', identifier: wake_lock_script['identifier']
    )
  end

  scenario 'enables, restores, and disables the preference' do # rubocop:disable RSpec/ExampleLength
    check 'Keep screen awake', allow_label_click: true
    expect(page).to have_field('Keep screen awake', checked: true, visible: :all)

    visit recipe_path(recipe)
    expect(page).to have_field('Keep screen awake', checked: true, visible: :all)

    uncheck 'Keep screen awake', allow_label_click: true
    visit recipe_path(recipe)
    expect(page).to have_field('Keep screen awake', checked: false, visible: :all)
  end
end
