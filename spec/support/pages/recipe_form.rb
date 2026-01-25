class RecipeForm < SitePrism::Section
  element :name_field, '[name="recipe[name]"]'
  element :yield_field, '[name="recipe[yield]"]'
  element :prep_time_field, '[name="recipe[prep_time]"]'
  element :cook_time_field, '[name="recipe[cook_time]"]'
  element :category_select, '[name="recipe[category_names][]"]'
  element :description_field, '[name="recipe[description]"]'
  element :ingredients_field, '[name="recipe[ingredients]"]'
  element :directions_field, '[name="recipe[directions]"]'
  element :notes_field, '[name="recipe[notes]"]'
  element :rating_container, '#recipe_rating'
  element :save_button, 'button', text: 'Save'

  def fill_form(recipe_data)
    name_field.set(recipe_data[:name]) if recipe_data[:name]
    yield_field.set(recipe_data[:yield]) if recipe_data[:yield]
    prep_time_field.set(recipe_data[:prep_time]) if recipe_data[:prep_time]
    cook_time_field.set(recipe_data[:cook_time]) if recipe_data[:cook_time]
    description_field.set(recipe_data[:description]) if recipe_data[:description]
    ingredients_field.set(recipe_data[:ingredients]) if recipe_data[:ingredients]
    directions_field.set(recipe_data[:directions]) if recipe_data[:directions]
    notes_field.set(recipe_data[:notes]) if recipe_data[:notes]

    # Select rating if provided
    if recipe_data[:rating]
      Capybara.current_session.choose "recipe_rating_#{recipe_data[:rating]}"
    end

    # Add categories if provided
    if recipe_data[:categories]
      recipe_data[:categories].each do |category|
        # For tom-select, we need to click to open and then select
        category_select.click
        find('.ts-dropdown .ts-dropdown-content .option', text: category).click
      end
    end
  end

  def submit_form
    save_button.click
  end

  def create_recipe(recipe_data)
    fill_form(recipe_data)
    submit_form
  end
end
