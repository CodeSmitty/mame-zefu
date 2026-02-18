require_relative 'recipe_form'

class NewRecipePage < BasePage
  set_url '/recipes/new'

  section :recipe_form, RecipeForm, '.form-container'
  element :save_button, 'button', text: 'Save'

  def submit_form
    save_button.click
  end

  def save_recipe(recipe_data)
    recipe_form.fill_form(recipe_data)
    submit_form
  end
end
