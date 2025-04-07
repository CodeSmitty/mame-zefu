require 'rails_helper'
require './spec/support/features/clearance_helpers'

RSpec.describe 'Recipes' do
  let(:user) { create(:user) }
  let(:recipe_name) { 'Spaghetti' }
  let(:category_name) { 'Italian' }
  let(:category) { Category.create(name: category_name) }
  let!(:recipe) { Recipe.create(name: recipe_name, categories: [category], user: user) }
  let(:other_user) { create(:user) }

  describe 'GET /recipes' do
    context 'when unauthenticated' do
      it 'redirects to login' do
        get '/recipes'
        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe 'GET /recipes/:id' do
    context 'when unauthenticated' do
      it 'redirects to login' do
        get recipe_path(:id)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when unuathenticated and recipe non owner' do
      before { sign_in(other_user) }

      it 'does not show recipes to non owner.' do
        expect { get recipe_path(recipe) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe 'POST /recipes' do
    context 'when user is unauthenticated' do
      it 'redirects to login' do
        post '/recipes'
        puts user.id
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when user is authenticated' do

      it 'creates recipe for signed in user.' do
        post recipes_path, params: { recipe: attributes_for(:recipe) }
        follow_redirect!
        puts recipe.user.id
        puts user.id
        expect(response).to have_http_status(:ok)
      end
    end
  end

  private

  def sign_in(user)
    post session_path, params: {
      session: {
        email: user.email,
        password: 'password'
      }
    }
    follow_redirect!
  end
end
