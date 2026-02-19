require 'rails_helper'

RSpec.feature 'User creates a recipe' do
  given(:user) { create(:user) }
  given(:home_page) { HomePage.new }
  given(:new_recipe_page) { NewRecipePage.new }
  given(:recipe_show_page) { RecipeShowPage.new }

  given(:recipe_data) do
    {
      name: 'Chocolate Chip Cookies',
      yield: '60',
      prep_time: '25 minutes',
      cook_time: '8 minutes',
      total_time: '33 minutes',
      categories: %w[Snack Cookie],
      description: <<~TEXT.chomp,
        A delicious cookie recipe.
      TEXT
      ingredients: <<~TEXT.chomp,
        2 1/4 cups all-purpose flour
        1 tsp baking soda
        1/2 tsp salt
        1 cup butter, softened
        3/4 cup granulated sugar
        3/4 cup packed light brown sugar
        1 tsp vanilla extract
        2 eggs
        2 cups dark chocolate chips
      TEXT
      directions: <<~TEXT.chomp,
        Heat oven to 375°F.

        Combine ingredients. Place on cookie sheet.

        Bake 8 to 10 minutes.
      TEXT
      notes: <<~TEXT.chomp,
        Santa's favorite!
      TEXT
      rating: 5
    }
  end

  background do
    Category.from_names(recipe_data[:categories], user:)

    visit root_path(as: user)
  end

  scenario 'successfully' do
    home_page.new_recipe_link.click

    new_recipe_page.save_recipe(recipe_data)

    expect(home_page).to have_content('Recipe was successfully created.')
    user_sees_recipe(recipe_data)
  end

  def user_sees_recipe(recipe_data)
    %i[name yield prep_time cook_time total_time description].each { |field| expect_simple_text(field) }
    %i[ingredients directions].each { |field| expect_complex_text(field) }
    expect(recipe_show_page.recipe_categories.map(&:text)).to eq(recipe_data[:categories].sort_by(&:downcase))
  end

  def expect_simple_text(field)
    expect(recipe_show_page.send(:"recipe_#{field}")).to have_text(recipe_data[field])
  end

  def expect_complex_text(field)
    expect(recipe_show_page.send(:"recipe_#{field}").map(&:text)).to eq(recipe_data[field].split(/\n+/))
  end
end
