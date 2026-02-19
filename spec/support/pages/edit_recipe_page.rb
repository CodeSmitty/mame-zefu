require_relative 'recipe_form'

class EditRecipePage < BasePage
  set_url '/recipes/{id}/edit'

  section :recipe_form, RecipeForm, '.form-container'
  element :save_button, 'button', text: 'Save'
  element :cancel_button, :link, 'Cancel'

  def submit_form
    save_button.click
  end

  def save_recipe(recipe_data)
    recipe_form.fill_form(recipe_data)
    submit_form
  end
end
