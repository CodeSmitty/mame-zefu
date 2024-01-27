json.extract! recipe, :id, :name, :ingredients, :directions, :yield, :prep_time, :cook_time, :rating, :is_favorite, :description, :notes, :created_at, :updated_at
json.url recipe_url(recipe, format: :json)
