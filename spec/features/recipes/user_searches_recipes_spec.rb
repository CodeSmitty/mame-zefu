require 'rails_helper'

RSpec.feature 'User searches recipes', :js do
  given(:user) { create(:user) }
  given!(:soup) { create(:recipe, user:, name: 'Tomato soup', category_names: ['Lunch']) }
  given!(:cake) { create(:recipe, user:, name: 'Chocolate cake', category_names: ['Dessert']) }

  scenario 'filters results while keeping focus in the search field' do # rubocop:disable RSpec/ExampleLength
    visit recipes_path(as: user)
    Selenium::WebDriver::Wait.new(timeout: 10).until do
      page.evaluate_script(<<~JS)
        !!window.Stimulus?.getControllerForElementAndIdentifier(
          document.querySelector('form[data-controller=filter]'), 'filter'
        )
      JS
    end
    fill_in 'Search', with: 'soup'

    expect(page).to have_link(soup.name)
    expect(page).to have_no_link(cake.name)
    expect(page.evaluate_script('document.activeElement.id')).to eq('query')
  end

  scenario 'requests keyboard suggestions be disabled for the category search' do
    visit recipes_path(as: user)
    category_input = find('.ts-control input')

    expect(category_input[:autocomplete]).to eq('off')
    expect(category_input.native.dom_attribute('autocorrect')).to eq('off')
    expect(category_input.native.dom_attribute('spellcheck')).to eq('false')
  end

  scenario 'filters by category using the category search input' do # rubocop:disable RSpec/ExampleLength
    visit recipes_path(as: user)
    category_input = find('.ts-control input')
    category_input.fill_in with: 'Lunch'
    find('.ts-dropdown .option', text: 'Lunch').click

    expect(page).to have_link(soup.name)
    expect(page).to have_no_link(cake.name)
  end

  scenario 'still allows creating a category when editing a recipe' do
    visit new_recipe_path(as: user)
    find('.ts-control input').fill_in with: 'New category'
    find('.ts-dropdown .create', text: 'New category').click

    expect(page).to have_css('.ts-control .item', text: 'New category')
  end

  scenario 'shows a result above a simulated mobile keyboard and keeps download in the menu' do # rubocop:disable RSpec/ExampleLength
    page.current_window.resize_to(390, 700)
    visit recipes_path(as: user)
    find('.ts-control input')
    find_by_id('query').click

    result_bottom = page.evaluate_script("document.querySelector('#recipes a.recipe').getBoundingClientRect().bottom")
    navigation_bottom = page.evaluate_script("document.querySelector('nav').getBoundingClientRect().bottom")
    search_top = page.evaluate_script("document.querySelector('#query').getBoundingClientRect().top")

    expect(result_bottom).to be <= 350
    expect(search_top).to be >= navigation_bottom
    expect(page).to have_no_link('Download')

    find('button[aria-controls="navbar-default"]').click
    expect(page).to have_link('Download', href: archive_download_recipes_path)
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  scenario 'keeps the first result close to the favorite filter on small screens' do # rubocop:disable RSpec/ExampleLength
    page.current_window.resize_to(320, 700)
    visit recipes_path(as: user)
    find('.ts-control input')

    gap = page.evaluate_script(<<~JS)
      document.querySelector('#recipes a.recipe').getBoundingClientRect().top -
        document.querySelector('input[name=is_favorite]').closest('label').getBoundingClientRect().bottom
    JS
    height = page.evaluate_script("document.querySelector('#recipes a.recipe').getBoundingClientRect().height")

    expect(gap).to be_between(0, 16)
    expect(height).to be >= 44
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  scenario 'opens the download page from the mobile menu' do # rubocop:disable RSpec/ExampleLength
    page.current_window.resize_to(390, 700)
    visit recipes_path(as: user)
    find('button[aria-controls="navbar-default"]').click
    within('nav') { click_link 'Download' }

    expect(page).to have_current_path('/recipes/archive/download')
    expect(page).to have_css('h1', text: 'Download Recipes')
    expect(page).to have_css(
      "main a[href='#{archive_download_file_recipes_path}'][data-turbo='false']", text: 'Download'
    )
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  scenario 'retains the larger gap on desktop' do # rubocop:disable RSpec/ExampleLength
    page.current_window.resize_to(1024, 700)
    visit recipes_path(as: user)
    find('.ts-control input')

    gap = page.evaluate_script(<<~JS)
      document.querySelector('#recipes a.recipe').getBoundingClientRect().top -
        document.querySelector('input[name=is_favorite]').closest('label').getBoundingClientRect().bottom
    JS
    expect(gap).to be >= 32
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  scenario 'keeps the expanded mobile menu scrollable on a short screen' do # rubocop:disable RSpec/ExampleLength
    page.current_window.resize_to(320, 400)
    visit recipes_path(as: user)
    find('button[aria-controls="navbar-default"]').click

    expect(page.evaluate_script(<<~JS)).to be true
      document.querySelector('#navbar-default').scrollHeight > document.querySelector('#navbar-default').clientHeight
    JS
    page.execute_script(<<~JS)
      document.querySelector('#navbar-default').scrollTop = document.querySelector('#navbar-default').scrollHeight
    JS
    expect(page).to have_button('Sign out')
    expect(page.evaluate_script("document.querySelector('nav button[type=submit]').getBoundingClientRect().bottom"))
      .to be <= page.evaluate_script('window.innerHeight')
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  scenario 'keeps desktop navigation on one line with all links enabled' do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    allow(Recipes::Extraction).to receive(:enabled?).and_return(true)
    admin = create(:user, is_admin: true)
    page.current_window.resize_to(1024, 700)
    visit recipes_path(as: admin)

    expect(page).to have_link('Extract')
    expect(page).to have_link('Admin')
    expect(page).to have_link('Download', href: archive_download_recipes_path)
    expect(page.evaluate_script("document.querySelector('nav').getBoundingClientRect().height")).to be <= 80
    expect(page.evaluate_script('document.documentElement.scrollWidth')).to be <= 1024
  ensure
    page.current_window.resize_to(1400, 1400)
  end
end
