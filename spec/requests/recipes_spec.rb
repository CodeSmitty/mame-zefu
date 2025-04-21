require 'rails_helper'

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
      it 'does not show recipes for another user.' do
        expect { get recipe_path(recipe, as: other_user) }.to raise_error(Pundit::NotAuthorizedError)
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
      it 'creates recipe for user.' do
        expect { post recipes_path(params: { recipe: attributes_for(:recipe) }, as: user) }
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
      it 'returns 200' do
        expect { put recipe_path(recipe, as: user), params: { recipe: { name: 'new name' } } }
          .to change { recipe.reload.name }.from(recipe.name).to('new name')
        expect(response).to redirect_to(recipe_path(recipe))
        follow_redirect!
        expect(response).to have_http_status(:success)
      end

      it 'does not update recipe for other user.' do
        expect { put recipe_path(recipe, as: other_user) }.to raise_error(Pundit::NotAuthorizedError)
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
      it 'returns 200' do
        post toggle_favorite_recipe_path(recipe, as: user)
        expect(response).to have_http_status(:ok)
      end

      it 'toggles is_favorite on recipe' do
        expect { post toggle_favorite_recipe_path(recipe, as: user), params: { recipe: { is_favorite: true } } }
          .to change { recipe.reload.is_favorite }.from(false).to(true)
        expect(response).to have_http_status(:ok)
      end

      it 'does not toggle favorite for anohter user.' do
        expect { post toggle_favorite_recipe_path(recipe, as: other_user) }.to raise_error(Pundit::NotAuthorizedError)
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
      it 'returns 204' do
        delete recipe_path(recipe, as: user)
        follow_redirect!
        expect(response).to have_http_status(:ok)
      end

      it 'deletes recipe' do
        expect { delete recipe_path(recipe, as: user) }.to change { Recipe.count }.by(-1) # rubocop:disable RSpec/ExpectChange
      end

      it 'does not delete delete recipe of another user.' do
        expect { delete recipe_path(recipe, as: other_user) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
