module RecipesHelper
  def delete_image_url(recipe)
    return unless recipe.image.persisted?

    image_recipe_path(recipe)
  end

  def preview_image_src(recipe)
    if recipe.image_src.present?
      recipe.image_src
    elsif recipe.image.attached? && !recipe.image.persisted?
      url_for(recipe.image)
    end
  end

  def persisted_image_src(recipe)
    return unless recipe.image.persisted?

    url_for(recipe.image)
  end

  def default_image_src
    asset_path('camera.png')
  end
end
