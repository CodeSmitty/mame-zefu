class RecipePolicy < ApplicationPolicy
  attr_reader :user, :recipe

  def initialize(user, recipe)
    @user = user
    @recipe = recipe
  end

  def create?
    owner?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  def toggle_favorite?
    owner?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(user: user)
    end

    private

    attr_reader :user, :scope
  end

  private

  def owner?
    user == recipe.user
  end
end
