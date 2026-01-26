require 'rails_helper'

RSpec.describe RecipePolicy do
  subject(:policy) { described_class }

  let!(:user) { create(:user) }
  let!(:user_recipe) { create(:recipe, user: user) }
  let!(:other_user) { create(:user) }
  let!(:other_user_recipe) { create(:recipe, user: other_user) }

  permissions :show?, :update?, :destroy?, :toggle_favorite?, :delete_image? do
    it 'grants access to the owner' do
      expect(policy).to permit(user, user_recipe)
    end

    it 'denies access to non-owners' do
      expect(policy).not_to permit(other_user, user_recipe)
    end
  end

  describe RecipePolicy::Scope do
    subject(:scope) { described_class.new(user, Recipe.all) }

    it 'resolves to recipes owned by the user' do
      expect(scope.resolve).to include(user_recipe)
      expect(scope.resolve).not_to include(other_user_recipe)
    end
  end
end
