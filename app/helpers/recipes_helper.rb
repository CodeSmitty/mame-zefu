module RecipesHelper
  def recipe_extraction_enabled?
    Recipes::Extraction.enabled?(current_user)
  end

  def ingredient_parsing_enabled?
    Feature.ingredient_parsing_enabled?(current_user)
  end

  def recipe_draft_key(recipe)
    draft_id = recipe.persisted? ? recipe.id : 'new'

    "user:#{current_user.id}:recipe:#{draft_id}"
  end

  def category_select_options(recipe)
    user = recipe.user || current_user
    existing_categories = user.categories.pluck(:name)
    pending_categories = recipe.pending_category_names || []

    category_options(existing_categories + pending_categories)
  end

  def category_filter_options(user = current_user)
    category_options(user.categories.pluck(:name))
  end

  def parsed_ingredient_markup(item)
    return item unless ingredient_parsing_enabled?

    ingredient = Ingredient::Parser.new(item).parse || Ingredient.new(name: item)
    content = safe_join(ingredient_pieces(ingredient), ' ')

    ingredient_debug_markup(content, ingredient, item)
  end

  private

  def ingredient_debug_markup(content, ingredient, original)
    return content unless current_user&.is_admin?

    content_tag(:span, data: { controller: 'ingredient-debug' }) do
      safe_join([debug_toggle_button, content, debug_panel(ingredient, original)])
    end
  end

  def debug_toggle_button
    icon = render('icons/micro/magnifying_glass', classes: '')

    content_tag(:button, icon, type: 'button',
                               class: 'ingredient-debug-toggle text-gray-500 align-middle me-1 cursor-pointer ' \
                                      'no-underline',
                               data: { action: 'click->ingredient-debug#toggle:stop' })
  end

  def debug_panel(ingredient, original)
    # Wrapped in an inline-block span so the ancestor <li>'s line-through decoration
    # (toggled by the strikethrough feature) doesn't paint through this block-level <pre>.
    # The "hidden" toggle class stays on the <pre> itself to avoid colliding with
    # "inline-block" on the same element (both are display utilities with equal
    # specificity, and Tailwind's generated order would let inline-block win).
    content_tag(:span, class: 'inline-block') do
      content_tag(:pre, JSON.pretty_generate(ingredient.attributes.merge('original' => original)),
                  class: 'ingredient-debug-panel hidden mt-1 p-2 text-xs bg-gray-100 rounded whitespace-pre-wrap',
                  data: { ingredient_debug_target: 'panel' })
    end
  end

  def ingredient_pieces(ingredient)
    [quantity_piece(ingredient), unit_piece(ingredient), ingredient_piece(ingredient)].compact
  end

  def quantity_piece(ingredient)
    return if ingredient.formatted_quantity.blank?

    content_tag(:span, ingredient.formatted_quantity,
                class: 'ingredient-quantity font-semibold tabular-nums')
  end

  def unit_piece(ingredient)
    return if ingredient.formatted_unit.blank?

    content_tag(:span, ingredient.formatted_unit,
                class: 'ingredient-unit font-semibold font-mono')
  end

  def ingredient_piece(ingredient)
    content_tag(:span, ingredient.name, class: 'ingredient-name')
  end

  def category_options(category_names)
    category_names
      .uniq(&:downcase)
      .sort_by(&:downcase)
      .map { |name| [name, name] }
  end
end
