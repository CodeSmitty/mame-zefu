require 'rails_helper'
require 'support/shared_examples/admin_route'

RSpec.describe 'Admin' do
  describe 'GET /admin/users' do
    it_behaves_like 'an admin-only route', :get, -> { admin_users_path }
  end

  describe 'GET /admin/users/:id' do
    let(:user) { create(:user) }

    it_behaves_like 'an admin-only route', :get, -> { admin_user_path(user) }
  end

  describe 'GET /admin/recipes' do
    it_behaves_like 'an admin-only route', :get, -> { admin_recipes_path }
  end

  describe 'GET /admin/recipes/:id' do
    let(:recipe) { create(:recipe) }

    it_behaves_like 'an admin-only route', :get, -> { admin_recipe_path(recipe) }
  end

  describe 'GET /admin/categories' do
    it_behaves_like 'an admin-only route', :get, -> { admin_categories_path }
  end

  describe 'GET /admin/categories/:id' do
    let(:category) { create(:category) }

    it_behaves_like 'an admin-only route', :get, -> { admin_category_path(category) }
  end
end
