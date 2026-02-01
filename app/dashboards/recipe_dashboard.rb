require 'administrate/base_dashboard'

class RecipeDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    source: Field::String,
    is_favorite: Field::Boolean,
    rating: Field::Number,
    yield: Field::String,
    prep_time: Field::String,
    cook_time: Field::String,
    categories: Field::HasMany,
    description: Field::Text,
    ingredients: Field::Text,
    directions: Field::Text,
    notes: Field::Text,
    user: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    categories
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    source
    is_favorite
    rating
    yield
    prep_time
    cook_time
    categories
    description
    ingredients
    directions
    notes
    user
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    source
    is_favorite
    rating
    yield
    prep_time
    cook_time
    categories
    description
    ingredients
    directions
    notes
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(recipe)
    recipe.name
  end
end
