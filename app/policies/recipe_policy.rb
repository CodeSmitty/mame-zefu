class RecipePolicy
    attr_reader :user, :recipe
  
    def initialize(user, recipe)
      @user = user
      @recipe = recipe
    end

    def create?
        is_owner?
    end
  
    def update?
      is_owner? 
    end

    def destroy?
        is_owner?
    end

    def toggle_favorite?
        is_owner?
    end

    private

    def is_owner?
        user == recipe.user
    end
    
  end