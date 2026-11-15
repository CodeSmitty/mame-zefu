require 'rails_helper'

RSpec.feature 'User searches the web for a recipe', :js do
  given(:user) { create(:user) }
  given(:recipe_url) { 'https://example.com/recipes/cake?servings=2&unit=cups' }
  given(:import_service) { instance_double(Recipes::Import, recipe: Recipe.new(name: 'Imported cake')) }

  background do
    page.driver.browser.execute_cdp('Network.enable')
    page.driver.browser.execute_cdp('Network.setBlockedURLs', urls: ['*://cse.google.com/*'])
    allow(Recipes::Import).to receive(:new).and_return(import_service)

    visit web_search_recipes_path(as: user)
  end

  after do
    page.driver.browser.execute_cdp('Network.setBlockedURLs', urls: [])
    page.driver.browser.execute_cdp('Network.disable')
  end

  context 'when the search box is inserted' do
    background do
      insert_google_markup('search-input', <<~HTML)
        <form>
          <label for="google-recipe-search">Recipe search</label>
          <input id="google-recipe-search" class="gsc-input">
          <button type="submit">Search</button>
        </form>
      HTML
      find_field('Recipe search', placeholder: 'Search or paste a recipe URL')
    end

    scenario 'imports a pasted URL when Enter is pressed' do
      fill_in 'Recipe search', with: "  #{recipe_url}  "
      find_field('Recipe search').send_keys(:enter)

      expect_imported_recipe
    end

    scenario 'imports a pasted URL when the search button is clicked' do
      fill_in 'Recipe search', with: recipe_url
      click_button 'Search'

      expect_imported_recipe
    end

    scenario 'allows a search phrase to be submitted as a search' do
      simulate_google_search
      fill_in 'Recipe search', with: 'chocolate cake'
      find_field('Recipe search').send_keys(:enter)

      expect(page).to have_text('Search submitted')
    end

    scenario 'allows an invalid URL to be submitted as a search' do
      simulate_google_search
      fill_in 'Recipe search', with: 'https://'
      click_button 'Search'

      expect(page).to have_text('Search submitted')
    end
  end

  context 'when search results are inserted' do
    background do
      insert_google_markup('search-results', <<~HTML)
        <div class="gsc-result">
          <a href="#{recipe_url}">Chocolate cake</a>
          <a href="#{recipe_url}">
            <img alt="Chocolate cake preview" width="20" height="20"
                 src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7">
          </a>
        </div>
      HTML
    end

    context 'when a mobile preview image is inserted' do
      background do
        insert_google_markup('search-results', <<~HTML)
          <div class="gs-mobilePreview"><a href="#{recipe_url}"></a></div>
        HTML
        page.execute_script(<<~JS)
          document.querySelector('.gs-mobilePreview a').insertAdjacentHTML(
            'beforeend',
            '<img class="gs-imagePreview" alt="Mobile preview" width="20" height="20" ' +
              'src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7">'
          )
        JS
      end

      scenario 'imports the clicked mobile preview' do
        click_link 'Mobile preview'

        expect_imported_recipe
      end
    end

    scenario 'imports the clicked search result' do
      click_link 'Chocolate cake'

      expect_imported_recipe
    end

    scenario 'imports the clicked result image' do
      click_link 'Chocolate cake preview'

      expect_imported_recipe
    end
  end

  def expect_imported_recipe
    expect(page).to have_current_path(web_result_recipes_path(url: recipe_url))
    expect(page).to have_field('Name', with: 'Imported cake')
  end

  def simulate_google_search
    page.execute_script(<<~JS)
      document.querySelector('[data-controller="search-input"] form').addEventListener('submit', (event) => {
        event.preventDefault()
        document.querySelector('.gcse-searchresults').textContent = 'Search submitted'
      })
    JS
  end

  def insert_google_markup(controller, markup) # rubocop:disable Metrics/MethodLength
    page.evaluate_async_script(<<~JS, controller, markup)
      const [identifier, markup, done] = arguments
      const element = document.querySelector(`[data-controller="${identifier}"]`)
      const insert = () => {
        if (!window.Stimulus?.getControllerForElementAndIdentifier(element, identifier)) {
          requestAnimationFrame(insert)
          return
        }
        element.firstElementChild.insertAdjacentHTML('beforeend', markup)
        done()
      }
      insert()
    JS
  end
end
