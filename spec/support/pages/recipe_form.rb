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

  TEXT_FIELDS = %i[name yield prep_time cook_time description ingredients directions notes].freeze

  TEXT_FIELDS.each do |field|
    define_method("#{field}_value=") do |value|
      send("#{field}_field").set(value) if value.present?
    end
  end

  def rating_value=(value)
    Capybara.current_session.choose "recipe_rating_#{value}" if value.present?
  end

  def categories_value=(categories)
    return if categories.blank?

    categories.each do |category|
      category_select.select(category)
    end
  end

  def fill_form(recipe_data)
    recipe_data.each do |field, value|
      setter = "#{field}_value="
      send(setter, value) if respond_to?(setter)
    end
  end

  def submit_form
    save_button.click
  end

  def save_recipe(recipe_data)
    fill_form(recipe_data)
    submit_form
  end
end
