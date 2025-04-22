class RecipePolicy < ApplicationPolicy
  def show?
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
end
