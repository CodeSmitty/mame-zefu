require_relative 'recipe_form'

class NewRecipePage < BasePage
  set_url '/recipes/new'

  section :recipe_form, RecipeForm, '.form-container'
end
