require_relative 'recipe_form'

class EditRecipePage < BasePage
  set_url '/recipes/{id}/edit'

  section :recipe_form, RecipeForm, '.form-container'
  element :cancel_button, :link, 'Cancel'
end
