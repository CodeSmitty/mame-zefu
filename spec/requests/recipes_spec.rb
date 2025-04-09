require 'rails_helper'
require './spec/support/features/clearance_helpers'

RSpec.describe 'Recipes' do
  let(:user) { create(:user) }
  let(:recipe_name) { 'Spaghetti' }
  let(:category_name) { 'Italian' }
  let(:category) { Category.create(name: category_name) }
  let!(:recipe) { create(:recipe, user: user) }
  let(:other_user) { create(:user) }

  describe 'GET /recipes' do
    it 'returns a 200' do
      get recipes_path(params: { query: recipe.name, category_names: [category_name], as: user })
      expect(response).to have_http_status(:ok)
    end

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
        get recipe_path(recipe)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when authenticated' do
      it 'returns a 200' do
        get recipe_path(recipe, as: user)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when athenticated and recipe non owner' do
      before { sign_in(other_user) }

      it 'does not show recipes for another user.' do
        expect { get recipe_path(recipe) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe 'POST /recipes' do
    context 'when user is unauthenticated' do
      it 'redirects to login' do
        post '/recipes'
        expect { post recipes_path }.to redirect_to(sign_in_path)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      it 'creates recipe for user.' do
        expect { post recipes_path, params: { recipe: attributes_for(:recipe) } }
          .to change(Recipe, :count).by(1)

        follow_redirect!
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'PUT /recipes/:id' do
    context 'when user is unauthenticated' do
      it 'redirects to login' do
        put recipe_path(recipe), params: { recipe: { name: 'updated name' } }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when user updates recipe' do
      before { sign_in user }

      it 'returns 200' do
        expect { put recipe_path(recipe), params: { recipe: { name: 'new name' } } }
          .to change { recipe.reload.name }.from(recipe.name).to('new name')
        expect(response).to redirect_to(recipe_path(recipe))
        follow_redirect!
        expect(response).to have_http_status(:success)
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
