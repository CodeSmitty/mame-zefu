class RecipeShowPage < BasePage
  set_url '/recipes/{id}'

  element :recipe_name, 'h1 strong'
  element :edit_button, :link, 'Edit'
  element :delete_button, :button, 'Delete'

  def has_recipe_name?(name)
    recipe_name.text == name
  end

  def has_description?(description)
    has_css?('.my-5 p', text: description)
  end

  def has_ingredients?(ingredients)
    # Check if ingredients are displayed (this might need adjustment based on how they're rendered)
    ingredients.split("\n\n").all? do |ingredient_list|
      ingredient_list.split("\n").all? do |ingredient|
        has_css?('li', text: ingredient.strip)
      end
    end
  end

  def has_directions?(directions)
    # Check if directions are displayed
    directions.split("\n\n").all? do |direction|
      has_css?('li', text: direction.strip)
    end
  end

  def has_notes?(notes)
    has_css?('.my-5 p strong', text: 'Notes') &&
    notes.split("\n\n").all? do |note|
      has_css?('.my-5 p', text: note.strip)
    end
  end

  def has_rating?(rating)
    # Check for the correct number of stars
    has_css?('.text-yellow-300', count: rating.to_i)
  end

  def has_categories?(categories)
    categories.all? do |category|
      has_css?('.bg-yellow-50', text: category)
    end
  end

  def directions_text
    find('ol[data-controller="list"]').text
  end

  def has_directions_with_line_breaks?
    directions_text.include?("Foo") && directions_text.include?("Bar") && directions_text.include?("Baz")
  end
end
