class RecipeShowPage < BasePage
  set_url '/recipes/{id}'

  element :edit_button, :link, 'Edit'
  element :delete_button, :button, 'Delete'
end
