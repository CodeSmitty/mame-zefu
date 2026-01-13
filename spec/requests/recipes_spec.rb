require 'rails_helper'

RSpec.describe 'Recipes' do
  let(:user) { create(:user) }
  let(:recipe_name) { 'Spaghetti' }
  let(:category_name) { 'Italian' }
  let(:category) { Category.create(name: category_name) }
  let!(:recipe) { create(:recipe, user: user) }
  let(:other_user) { create(:user) }
  let(:other_recipe) { create(:recipe, user: other_user) }
  let(:image_path) { Rails.root.join('spec/fixtures/files/test.png') }
let(:uploaded_image) do
  fixture_file_upload(
    Rails.root.join('spec/fixtures/files/test.png'),
    'image/png'
  )
end

  let(:recipe_with_image) { attributes_for(:recipe, image: uploaded_image) }

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

      it 'creates recipe then attaches image (two-step like UI)' do
        expect {
          post recipes_path(params: { recipe: attributes_for(:recipe) }, as: user)
        }.to change(Recipe, :count).by(1)
        
        recipe = Recipe.last
        expect {
          recipe.image.attach(
            io: File.open(Rails.root.join('spec/fixtures/files/test.png')),
            filename: 'test.png',
            content_type: 'image/png'
          )
        }.to change(ActiveStorage::Attachment, :count).by(1)
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

      it 'deletes attached image when recipe is deleted' do
        recipe.image.attach(uploaded_image)

        expect {
          delete recipe_path(recipe, as: user)
        }.to change(ActiveStorage::Attachment, :count).by(-1)
      end
    end
  end

  describe 'GET /recipes/archive/download' do
    let(:tmpfile) do
      Tempfile.new('recipes-archive').tap do |tempfile|
        tempfile.write('zipdata')
        tempfile.rewind
      end
    end
    let(:archive_double) { instance_double(Recipes::Archive, generate: tmpfile) }

    before do
      allow(Recipes::Archive).to receive(:new).with(user).and_return(archive_double)
    end

    it 'redirects when unauthenticated' do
      get '/recipes/archive/download'
      expect(response).to redirect_to(sign_in_path)
    end

    it 'sends zip file when authenticated' do
      get archive_download_recipes_path(as: user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('zipdata')
      expect(response.headers['Content-Type']).to include('application/zip')
      expect(response.headers['Content-Disposition']).to match(/filename="Recipes_.*\.zip"/)
    end
  end

  describe 'GET /recipes/archive/upload' do
    it 'redirects when unauthenticated' do
      get '/recipes/archive/upload'
      expect(response).to redirect_to(sign_in_path)
    end

    it 'returns 200 when authenticated' do
      get archive_upload_recipes_path(as: user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /recipes/archive/upload' do
    let(:tempfile) do
      Tempfile.new('import').tap do |tempfile|
        tempfile.write('data')
        tempfile.rewind
      end
    end
    let(:uploaded_file) { Rack::Test::UploadedFile.new(tempfile.path, 'application/zip') }
    let(:archive_double) { instance_double(Recipes::Archive, restore: results) }
    let(:results) { { created: 1, skipped: 2 } }

    before do
      allow(Recipes::Archive).to receive(:new).with(user).and_return(archive_double)
    end

    it 'redirects when unauthenticated' do
      post '/recipes/archive/upload'
      expect(response).to redirect_to(sign_in_path)
    end

    it 'imports file and shows notice' do
      post archive_upload_recipes_path(as: user), params: { file: uploaded_file }

      expect(flash[:notice]).to eq('Imported 1 recipes (2 skipped)')
      expect(response).to redirect_to(recipes_path)
    ensure
      tempfile.close!
    end

    context 'when restore raises Recipes::Archive::Error' do
      before do
        allow(archive_double).to receive(:restore).and_raise(Recipes::Archive::Error.new('bad archive'))
      end

      it 'shows archive error message' do
        post archive_upload_recipes_path(as: user), params: { file: uploaded_file }

        expect(flash[:alert]).to eq('bad archive')
        expect(response).to redirect_to(recipes_path)
      ensure
        tempfile.close!
      end
    end

    context 'when restore raises StandardError' do
      before do
        allow(archive_double).to receive(:restore).and_raise(StandardError.new('boom'))
      end

      it 'shows generic error when StandardError occurs' do
        post archive_upload_recipes_path(as: user), params: { file: uploaded_file }

        expect(flash[:alert]).to eq('An unknown error occurred during import')
        expect(response).to redirect_to(recipes_path)
      ensure
        tempfile.close!
      end
    end
  end
end
