require 'administrate/base_dashboard'

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    email: Field::String,
    is_admin: Field::Boolean,
    recipes: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    email
    is_admin
    recipes
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    email
    is_admin
    recipes
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    is_admin
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(user)
    user.email
  end
end
