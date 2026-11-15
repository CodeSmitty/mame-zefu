require 'rails_helper'

RSpec.feature 'Recipe drafts', :js do
  given(:user) { create(:user) }
  given(:recipe) { create(:recipe, user:, name: 'Saved recipe') }
  given(:draft_key) { "recipe_draft:storage:user:#{user.id}:recipe:#{recipe.id}" }
  given(:new_draft_key) { "recipe_draft:storage:user:#{user.id}:recipe:new" }

  background do
    visit root_path(as: user)
    page.execute_script('localStorage.clear()')
  end

  after do
    page.execute_script('localStorage.clear()')
  end

  context 'when editing a recipe' do
    background do
      visit edit_recipe_path(recipe)
      wait_for_controller('recipe_form', 'recipe-draft')
    end

    context 'when the user leaves without saving' do
      background do
        fill_in 'Name', with: 'Unsaved recipe'
        fill_in 'Ingredients', with: "Flour\nSugar"
        wait_for_draft(draft_key, 'recipe[ingredients]', "Flour\nSugar")
        visit recipe_path(recipe)
      end

      scenario 'restores text fields through the review link' do
        click_link 'Review'
        expect(page).to have_field('Name', with: 'Unsaved recipe')
        expect(page).to have_field('Ingredients', with: "Flour\nSugar")
        expect(page).to have_text('Loaded unsaved changes.')
      end
    end

    scenario 'keeps the draft when the recipe fails validation' do
      fill_in 'Name', with: ''
      wait_for_draft(draft_key, 'recipe[name]', '')
      click_button 'Save'
      expect(page).to have_text("Name can't be blank")
      expect(storage_value(draft_key)).to be_present
    end

    scenario 'clears the draft after successfully saving' do
      fill_in 'Name', with: 'Updated recipe'
      wait_for_draft(draft_key, 'recipe[name]', 'Updated recipe')
      click_button 'Save'
      expect(page).to have_text('Recipe was successfully updated.')
      expect(storage_value(draft_key)).to be_nil
    end
  end

  context 'when reviewing a saved draft' do
    background do
      store_draft(draft_key, { 'recipe[name]' => 'Unsaved recipe' })
      store_draft(new_draft_key, { 'recipe[name]' => 'Another draft' })
      visit recipe_path(recipe)
      click_link 'Review'
    end

    scenario 'highlights restored changes' do
      expect(page).to have_field('Name', with: 'Unsaved recipe')
      expect(find_field('Name')['style']).to include('outline:')
    end

    scenario 'clears the highlight after editing' do
      expect(page).to have_field('Name', with: 'Unsaved recipe')
      fill_in 'Name', with: 'Another name'
      expect(find_field('Name')['style']).not_to include('outline:')
    end

    scenario 'discards the draft and returns to the saved recipe values' do
      click_button 'Discard'
      expect(page).to have_field('Name', with: 'Saved recipe')
      expect(page).to have_no_text('Loaded unsaved changes.')
      expect(storage_value(draft_key)).to be_nil
      expect(storage_value(new_draft_key)).to be_present
    end
  end

  context 'when new and existing recipes both have drafts' do
    background do
      store_draft(draft_key, { 'recipe[name]' => 'Existing draft' })
      store_draft(new_draft_key, { 'recipe[name]' => 'New draft' })
    end

    scenario 'keeps the drafts separate' do
      visit new_recipe_path
      expect(page).to have_field('Name', with: 'New draft')
      visit edit_recipe_path(recipe)
      expect(page).to have_field('Name', with: 'Existing draft')
    end
  end

  context 'when draft maintenance is due' do
    background do
      store_draft(draft_key, { 'recipe[name]' => 'Old draft' }, age: 31.days)
      store_draft(new_draft_key, { 'recipe[name]' => 'Recent draft' })
      page.execute_script(<<~JS)
        localStorage.setItem('recipe_draft:storage:broken', '{');
        localStorage.setItem('unrelated', 'keep');
        localStorage.setItem('recipe_draft:maintenance', '0');
      JS
      visit new_recipe_path
      expect(page).to have_field('Name', with: 'Recent draft')
    end

    scenario 'removes expired and malformed drafts' do
      expect(storage_value(draft_key)).to be_nil
      expect(storage_value('recipe_draft:storage:broken')).to be_nil
    end

    scenario 'preserves recent drafts and unrelated storage' do
      expect(storage_value(new_draft_key)).to be_present
      expect(storage_value('unrelated')).to eq('keep')
    end

    scenario 'records the maintenance time' do
      expect(storage_value('recipe_draft:maintenance').to_i).to be > 0
    end
  end

  context 'when maintenance ran recently' do
    background do
      store_draft(draft_key, { 'recipe[name]' => 'Old draft' }, age: 31.days)
      store_draft(new_draft_key, { 'recipe[name]' => 'Recent draft' })
      page.execute_script("localStorage.setItem('recipe_draft:maintenance', String(Date.now()))")
      visit new_recipe_path
      expect(page).to have_field('Name', with: 'Recent draft')
    end

    scenario 'does not run maintenance again within a day' do
      expect(storage_value(draft_key)).to be_present
    end
  end

  def store_draft(key, fields, age: 0)
    draft = { updatedAt: ((Time.current - age).to_f * 1000).to_i, fields: }
    page.execute_script('localStorage.setItem(arguments[0], JSON.stringify(arguments[1]))', key, draft)
  end

  def storage_value(key)
    page.evaluate_script('localStorage.getItem(arguments[0])', key)
  end

  def wait_for_controller(element_id, identifier)
    Selenium::WebDriver::Wait.new(timeout: Capybara.default_max_wait_time).until do
      page.evaluate_script(<<~JS, element_id, identifier)
        window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier(
          document.getElementById(arguments[0]), arguments[1]
        ) !== null
      JS
    end
  end

  def wait_for_draft(key, field, value)
    Selenium::WebDriver::Wait.new(timeout: Capybara.default_max_wait_time).until do
      raw = storage_value(key)
      raw && JSON.parse(raw).fetch('fields')[field] == value
    end
  end
end
