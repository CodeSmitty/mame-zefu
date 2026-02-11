class RecipeShowPage < BasePage
  set_url '/recipes/{id}'

  element :recipe_name, '[itemprop="name"]'
  element :recipe_yield, '[itemprop="recipeYield"]'
  element :recipe_prep_time, '[itemprop="prepTime"]'
  element :recipe_cook_time, '[itemprop="cookTime"]'
  elements :recipe_categories, '[itemprop="recipeCategory"]'
  element :recipe_description, '[itemprop="description"]'
  elements :recipe_ingredients, '[itemprop="recipeIngredient"]'
  elements :recipe_directions, '[itemprop="recipeInstructions"] li'
  element :edit_button, :link, 'Edit'
  element :delete_button, :button, 'Delete'
end
