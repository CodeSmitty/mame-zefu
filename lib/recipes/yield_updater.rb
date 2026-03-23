module Recipes
  class YieldUpdater
    Result = Struct.new(:success?, :yield_display, :ingredients)

    def initialize(recipe:, params:)
      @recipe = recipe
      @params = params
    end

    def call
      new_yield = @params[:new_yield].to_i
      source_yield = yield_source_value
      multiplier = Rational(new_yield, source_yield)
      yield_display = "#{new_yield} servings"
      scaled_ingredients = calculate_scaled_ingredients(multiplier, base_ingredients)

      if @recipe.update(yield: yield_display, ingredients: scaled_ingredients)
        Result.new(true, yield_display, scaled_ingredients)
      else
        Result.new(false, nil, nil)
      end
    end

    private

    def base_ingredients
      @params[:base_ingredients].presence || @recipe.ingredients.to_s
    end

    def calculate_scaled_ingredients(multiplier, ingredients)
      recipe_for_calculation = @recipe.dup
      recipe_for_calculation.ingredients = ingredients

      calculator = Recipes::IngredientCalculator.new(recipe_for_calculation)
      calculator.calculate_total_ingredients(recipe_for_calculation, multiplier)
    end

    def yield_source_value
      original_yield = @params[:original_yield].to_i
      base_yield = @params[:base_yield].to_i
      source_yield = base_yield.positive? ? base_yield : original_yield
      source_yield.positive? ? source_yield : 1
    end
  end
end
