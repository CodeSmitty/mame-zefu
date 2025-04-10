require 'rails_helper'
require './spec/support/features/clearance_helpers'

RSpec.describe 'Recipes' do
  let(:user) { create(:user) }
  let(:recipe_name) { 'Spaghetti' }
  let(:category_name) { 'Italian' }
  let(:category) { Category.create(name: category_name) }
  let!(:recipe) { create(:recipe, user: user) }
  let(:other_user) { create(:user) }
  let(:other_recipe) { create(:recipe, user: other_user) }

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
        expect(response).to redirect_to(sign_in_path)
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

      it 'does not update recipe for other user.' do
        sign_in other_user
        expect { put recipe_path(recipe) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe 'POST /recipes/:id/toggle_favorite' do
    context 'when user is unauthenticated' do
      it 'redirects to login' do
        post toggle_favorite_recipe_path(recipe)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when user is authenticated' do
      before { sign_in user }

      it 'returns 200' do
        post toggle_favorite_recipe_path(recipe)
        expect(response).to have_http_status(:ok)
      end

      it 'toggles is_favorite on recipe' do
        expect { post toggle_favorite_recipe_path(recipe), params: { recipe: { is_favorite: true } } }
          .to change { recipe.reload.is_favorite }.from(false).to(true)
        expect(response).to have_http_status(:ok)
      end

      it 'does not toggle favorite for anohter user.' do
        sign_in other_user

        expect { post toggle_favorite_recipe_path(recipe) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe 'DELETE /recipe/:id' do
    context 'when unauthenticated' do
      it 'redirects to login' do
        delete recipe_path(recipe)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'returns 204' do
        delete recipe_path(recipe)
        follow_redirect!
        expect(response).to have_http_status(:ok)
      end

      it 'deletes recipe' do
        expect { delete recipe_path(recipe) }.to change { Recipe.count }.by(-1) # rubocop:disable RSpec/ExpectChange
      end

      it 'does not delete delete recipe of another user.' do
        sign_in other_user

        expect { delete recipe_path(recipe) }.to raise_error(Pundit::NotAuthorizedError)
      end
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
