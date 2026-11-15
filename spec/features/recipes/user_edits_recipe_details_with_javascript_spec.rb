require 'rails_helper'

RSpec.feature 'User edits recipe details with JavaScript', :js do
  given(:user) { create(:user) }

  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  background { visit new_recipe_path(as: user) }

  scenario 'creates a category while entering a recipe' do
    fill_in 'Name', with: 'Berry tart'
    find('.ts-control input').fill_in with: 'Desserts'
    find('.ts-control input').send_keys(:enter)
    click_button 'Save'

    expect(page).to have_css('[itemprop="recipeCategory"]', text: 'Desserts')
  end

  scenario 'expands a text area as the user adds lines' do
    description = find_field('Description')
    initial_height = description.evaluate_script('this.offsetHeight')
    description.fill_in with: Array.new(12, 'A line of description').join("\n")

    expect(description.evaluate_script('this.offsetHeight')).to be > initial_height
  end

  scenario 'previews an uploaded image and cancels the selection' do # rubocop:disable RSpec/ExampleLength
    preview = find('[data-image-target="previewImage"]')
    original_src = preview[:src]
    attach_file 'upload-image-input', Rails.root.join('spec/fixtures/files/test.png'), make_visible: true

    expect(page).to have_css('[data-image-target="previewImage"][src^="data:image/png"]')
    find('[data-image-target="deleteButton"]').click
    expect(preview[:src]).to eq(original_src)
    expect(page).to have_no_css('[data-image-target="deleteButton"]')
  end

  scenario 'deletes an existing image' do # rubocop:disable RSpec/ExampleLength
    recipe = create(:recipe, user: user)
    Rails.root.join('spec/fixtures/files/test.png').open do |file|
      recipe.image.attach(io: file, filename: 'test.png')
    end
    visit edit_recipe_path(recipe)
    expect(page).to have_button('Replace Image')

    find('[data-image-target="deleteButton"]').click

    expect(page).to have_button('Upload Image')
    expect(recipe.reload.image).not_to be_attached
  end
end
