class RecipesController < ApplicationController
  before_action :require_login
  before_action :set_recipe, only: %i[show edit update destroy toggle_favorite]

  def web_search; end

  def web_result
    @recipe = Recipes::Import.from_url(params[:url])
  rescue Recipes::Import::UnknownHostError => e
    @recipe =
      Recipe.new.tap do |r|
        r.errors.add(:base, e.message)
      end
  end

  # GET /recipes or /recipes.json
  def index
    @recipes = policy_scope(Recipe.with_text(params[:query]).in_categories(params[:category_names]).sorted)
  end

  # GET /recipes/1 or /recipes/1.json
  def show; end

  # GET /recipes/new
  def new
    @recipe = current_user.recipes.build
  end

  # GET /recipes/1/edit
  def edit; end

  # POST /recipes or /recipes.json
  def create
    @recipe = current_user.recipes.build(recipe_params)

    respond_to do |format|
      if @recipe.save
        format.html { redirect_to recipe_url(@recipe), notice: 'Recipe was successfully created.' }
        format.json { render :show, status: :created, location: @recipe }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /recipes/1 or /recipes/1.json
  def update
    redirect_to :edit, notice: 'This user is not allowed to update this recipe.' unless authorize @recipe
    respond_to do |format|
      if @recipe.update(recipe_params)
        format.html { redirect_to recipe_url(@recipe), notice: 'Recipe was successfully updated.' }
        format.json { render :show, status: :ok, location: @recipe }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /recipes/1 or /recipes/1.json
  def destroy
    redirect_to :show, notice: 'This user is not allowed to delete this recipe.' unless authorize @recipe
    @recipe.destroy
    respond_to do |format|
      format.html { redirect_to recipes_url, notice: 'Recipe was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def toggle_favorite
    authorize @recipe
    @recipe.toggle!(:is_favorite) # rubocop:disable Rails/SkipsModelValidations
    render json: { is_favorite: @recipe.is_favorite }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_recipe
    @recipe = Recipe.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def recipe_params
    params.require(:recipe).permit(:name, :ingredients, :directions, :yield, :prep_time, :cook_time, :description,
                                   :rating, :is_favorite, :notes, :source, category_names: [])
  end
end
