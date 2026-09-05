module IngredientDebugHelper
  private

  def ingredient_debug_markup(content, original, measurements)
    return content unless current_user&.is_admin?

    content_tag(:span, data: { controller: 'ingredient-debug' }) do
      safe_join([debug_toggle_button, content, debug_panel(original, measurements)])
    end
  end

  def debug_toggle_button
    icon = render('icons/micro/magnifying_glass', classes: '')

    content_tag(:button, icon, type: 'button',
                               class: 'ingredient-debug-toggle text-gray-500 align-middle me-1 cursor-pointer ' \
                                      'no-underline',
                               data: { action: 'click->ingredient-debug#toggle:stop' })
  end

  def debug_panel(original, measurements)
    # Keep the debug panel's block display from inheriting the ancestor's line-through.
    content_tag(:span, class: 'inline-block') do
      content_tag(:pre, JSON.pretty_generate(debug_data(original, measurements)),
                  class: 'ingredient-debug-panel hidden mt-1 p-2 text-xs bg-gray-100 rounded whitespace-pre-wrap',
                  data: { ingredient_debug_target: 'panel' })
    end
  end

  def debug_data(original, measurements)
    { original: }.merge(measurements.transform_values { |value| value.is_a?(Hash) ? value.compact : value }).compact
  end
end
