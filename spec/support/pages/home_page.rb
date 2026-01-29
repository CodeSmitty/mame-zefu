class HomePage < BasePage
  set_url '/{recipes}'

  elements :recipe_links, 'a.recipe'

  def recipe_link(name)
    recipe_links.find { |link| link.text == name }
  end
end
