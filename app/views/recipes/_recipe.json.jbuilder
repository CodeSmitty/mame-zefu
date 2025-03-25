json.extract! recipe, :id, :name, :yield, :prep_time, :cook_time
json.categories recipe.category_names
json.extract! recipe, :description, :ingredients, :directions, :notes
json.extract! recipe, :is_favorite, :rating, :source
json.extract! recipe, :created_at, :updated_at
json.url recipe_url(recipe, format: :json)
