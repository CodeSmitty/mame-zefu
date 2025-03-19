require 'rails_helper'

RSpec.describe 'Recipes' do
  let(:recipe_name) { 'Spaghetti' }
  let(:category_name) { 'Italian' }
  let(:category) { Category.create(name: category_name) }
  let!(:recipe) { Recipe.create(name: recipe_name, categories: [category]) }

  describe 'GET /recipes' do
    it 'returns a 200' do
      get '/recipes', params: { query: recipe_name, category_names: [category_name] }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /recipes/:id' do
    it 'returns a 200' do
      get "/recipes/#{recipe.id}"

      expect(response).to have_http_status(:ok)
    end
  end
end
