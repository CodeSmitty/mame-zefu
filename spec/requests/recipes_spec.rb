require 'rails_helper'

RSpec.describe 'Recipes' do
  let(:user) { create(:user) }
  let(:category_name) { 'Italian' }
  let!(:recipe) { create(:recipe, user: user) }
  let(:other_user) { create(:user) }
  let(:uploaded_image) { fixture_file_upload('test.png', 'image/png') }

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

    context 'when recipe does not exist' do
      it 'returns 404' do
        get recipe_path(id: 'nonexistent', as: user)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when athenticated and recipe non owner' do
      it 'does not show recipes for another user.' do
        expect { get recipe_path(recipe, as: other_user) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe 'GET /recipes/new' do
    context 'when unauthenticated' do
      it 'redirects to login' do
        get new_recipe_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when authenticated' do
      it 'returns a 200' do
        get new_recipe_path(as: user)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /recipes/extraction' do
    before do
      allow(Recipes::Extraction).to receive(:enabled?).and_return(true)
    end

    it 'redirects when unauthenticated' do
      get extraction_recipes_path
      expect(response).to redirect_to(sign_in_path)
    end

    it 'returns 200 when authenticated' do
      get extraction_recipes_path(as: user)
      expect(response).to have_http_status(:ok)
    end

    context 'when extraction is disabled' do
      before do
        allow(Recipes::Extraction).to receive(:enabled?).and_return(false)
      end

      it 'redirects to recipes index' do
        get extraction_recipes_path(as: user)

        expect(response).to redirect_to(recipes_path)
      end
    end
  end

  describe 'GET /recipes/extraction/result/:token' do
    let(:token) { 'abc123' }

    before do
      allow(Recipes::Extraction).to receive(:enabled?).and_return(true)
    end

    context 'when unauthenticated' do
      it 'redirects to login' do
        get extraction_result_recipes_path(token:)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when authenticated' do
      context 'when extraction is disabled' do
        before do
          allow(Recipes::Extraction).to receive(:enabled?).and_return(false)
        end

        it 'redirects to recipes index' do
          get extraction_result_recipes_path(token:, as: user)

          expect(response).to redirect_to(recipes_path)
        end
      end

      context 'when token is valid' do
        let(:recipe_attributes) do
          {
            name: 'Toast',
            ingredients: "Bread\nButter",
            directions: "Toast bread\nSpread butter",
            category_names: ['Breakfast']
          }
        end

        before do
          allow(Recipes::Extraction::ResultStore).to receive(:fetch).with(user:, token:).and_return(recipe_attributes)
        end

        it 'returns 200 and shows extracted recipe page' do
          get extraction_result_recipes_path(token:, as: user)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Extracted Recipe')
          expect(response.body).to include('Toast')
          expect(response.body).to include('Bread')
        end
      end

      context 'when token is invalid or expired' do
        before do
          allow(Recipes::Extraction::ResultStore).to receive(:fetch).with(user:, token:).and_return(nil)
        end

        it 'redirects to extraction form' do
          get extraction_result_recipes_path(token:, as: user)

          expect(response).to redirect_to(extraction_recipes_path)
        end
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

    context 'when recipe fails validation' do
      it 'renders new template with errors' do
        post recipes_path(params: { recipe: attributes_for(:recipe, name: '') }, as: user)

        expect(response).to have_http_status(:unprocessable_content)
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

    context 'when update fails validation' do
      it 'renders edit template with errors' do
        put recipe_path(recipe, as: user), params: { recipe: { name: '' } }

        expect(response).to have_http_status(:unprocessable_content)
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

  describe 'DELETE /recipes/:id/image' do
    let(:recipe) { create(:recipe, user: user, image: uploaded_image) }

    context 'when authenticated' do
      it 'delete the image attachment' do
        expect do
          delete image_recipe_path(recipe, as: user)
        end.to change(ActiveStorage::Attachment, :count).by(-1)
      end

      it 'does not delete image of another user.' do
        expect { delete image_recipe_path(recipe, as: other_user) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when unauthenticated' do
      it 'redirects to login' do
        delete image_recipe_path(recipe)
        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe 'GET /recipes/web_search' do
    context 'when unauthenticated' do
      it 'redirects to login' do
        get web_search_recipes_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when authenticated' do
      it 'returns a 200' do
        get web_search_recipes_path(as: user)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /recipes/web_result' do
    let(:url) { 'https://example.com/recipe' }
    let(:import_service) { instance_double(Recipes::Import) }
    let(:imported_recipe) { build(:recipe) }

    before do
      allow(Recipes::Import).to receive(:new).and_return(import_service)
      allow(import_service).to receive(:recipe).and_return(imported_recipe)
    end

    context 'when unauthenticated' do
      it 'redirects to login' do
        get web_result_recipes_path(url: url)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when authenticated' do
      context 'when import is successful' do
        it 'returns a 200' do
          get web_result_recipes_path(url: url, as: user)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when import fails' do
        before do
          allow(import_service).to receive(:recipe).and_raise(StandardError.new('Import failed'))
        end

        it 'returns a 200 and shows an alert' do
          get web_result_recipes_path(url: url, as: user)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Unable to import recipe')
        end
      end
    end
  end

  describe 'POST /recipes/extraction' do
    let(:extracted_recipe) do
      Recipe.new(
        name: 'Toast',
        ingredients: "Bread\nButter",
        directions: "Toast bread\nSpread butter",
        category_names: ['Breakfast']
      )
    end
    let(:oversized_image_tempfile) do
      Tempfile.new(['too-large', '.jpg']).tap do |tempfile|
        tempfile.binmode
        tempfile.write('a' * (Recipe::MAX_IMAGE_SIZE + 1))
        tempfile.rewind
      end
    end

    after do
      oversized_image_tempfile.close! if instance_variable_defined?(:@oversized_image_tempfile)
    end

    before do
      allow(Recipes::Extraction).to receive(:enabled?).and_return(true)
    end

    context 'when unauthenticated' do
      it 'redirects to login' do
        post extraction_recipes_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when authenticated' do
      context 'when extraction is disabled' do
        before do
          allow(Recipes::Extraction).to receive(:enabled?).and_return(false)
        end

        it 'redirects to recipes index' do
          post extraction_recipes_path(as: user), params: { image: uploaded_image }

          expect(response).to redirect_to(recipes_path)
        end
      end

      context 'when extraction succeeds' do
        let(:token) { 'token-123' }

        before do
          allow(Recipes::Extraction).to receive(:from_file).and_return(extracted_recipe)
          allow(Recipes::Extraction::ResultStore).to receive(:store)
            .with(user:, recipe: extracted_recipe)
            .and_return(token)
          post extraction_recipes_path(as: user), params: { image: uploaded_image }
        end

        it 'redirects to extraction result' do
          expect(response).to redirect_to(extraction_result_recipes_path(token:))
        end
      end

      context 'when extraction raises an error' do
        before do
          allow(Recipes::Extraction).to receive(:from_file).and_raise(Recipes::Extraction::Error, 'Extraction failed')
          post extraction_recipes_path(as: user), params: { image: uploaded_image }
        end

        it 'returns unprocessable status' do
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'shows extraction form with error' do
          expect(response.body).to include('Extract Recipe from Image')
          expect(response.body).to include('Extraction failed')
        end
      end

      context 'when image is missing' do
        it 'returns unprocessable status' do
          post extraction_recipes_path(as: user)

          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'shows invalid file message' do
          post extraction_recipes_path(as: user)

          expect(response.body).to include('Image is required and must be a valid file.')
        end
      end

      context 'when image param is not an uploaded file' do
        it 'returns unprocessable status' do
          post extraction_recipes_path(as: user), params: { image: 'not-a-file' }

          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'shows image required message' do
          post extraction_recipes_path(as: user), params: { image: 'not-a-file' }

          expect(response.body).to include('Image is required and must be a valid file.')
        end
      end

      context 'when upload is not an image' do
        before do
          allow(Recipes::Extraction).to receive(:from_file).and_call_original
          post extraction_recipes_path(as: user), params: { image: uploaded_text_file }
        end

        it 'renders unsupported file type status' do
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'shows unsupported file type message' do
          expect(response.body).to include('Unsupported file type. Image is required.')
        end
      end

      context 'when image mime type is unsupported' do
        before do
          allow(Recipes::Extraction).to receive(:from_file).and_call_original
          post extraction_recipes_path(as: user), params: { image: uploaded_svg_file }
        end

        it 'returns unprocessable status' do
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'shows unsupported type message' do
          expect(response.body).to include('Unsupported file type. Image is required.')
        end
      end

      context 'when upload exceeds max size' do
        before do
          allow(Recipes::Extraction).to receive(:from_file).and_call_original
          post extraction_recipes_path(as: user), params: { image: oversized_image_file }
        end

        it 'returns unprocessable status' do
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'shows max size message' do
          expect(response.body).to include('Image is too large. Maximum allowed size is 5 MB.')
        end
      end
    end

    def uploaded_text_file
      Rack::Test::UploadedFile.new(
        StringIO.new('not an image'),
        'text/plain',
        original_filename: 'not-image.txt'
      )
    end

    def uploaded_svg_file
      Rack::Test::UploadedFile.new(
        StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"><text>Recipe</text></svg>'),
        'image/svg+xml',
        original_filename: 'recipe.svg'
      )
    end

    def oversized_image_file
      Rack::Test::UploadedFile.new(oversized_image_tempfile.path, 'image/jpeg')
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
