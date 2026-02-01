require 'administrate/base_dashboard'

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    email: Field::String,
    recipes: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    email
    recipes
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    email
    recipes
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    email
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(user)
    user.email
  end
end
