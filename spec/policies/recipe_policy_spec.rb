require 'rails_helper'
require './spec/support/features/clearance_helpers'

RSpec.describe RecipePolicy, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:recipe) { create(:recipe, user: user) }

  context 'when unauthenticated' do
    it 'redirects to login' do
      get '/recipes'
      expect(response).to redirect_to(sign_in_path)
    end
  end

  context 'when unuathenticated and recipe non owner' do
    subject { described_class.new(user, recipe) }

    it 'redirects to login' do
      get '/recipes/:id'
      expect(response).to redirect_to(sign_in_path)
    end

    it 'does not show recipes to non owner.' do
      get "/recipes/#{other_user.id}"
      expect(subject).to forbid_action(:index)
    end
  end
end
