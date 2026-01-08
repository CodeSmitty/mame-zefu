class RecipesController < ApplicationController
  before_action :require_login
  before_action :set_recipe, only: %i[show edit update destroy toggle_favorite]
  skip_after_action :verify_pundit_authorization, only: %i[
    web_search web_result
    download_archive upload_archive_form upload_archive
    new create
  ]

  def web_search; end

  def web_result
    @recipe = Recipes::Import.from_url(params[:url])
  rescue Recipes::Import::UnknownHostError => e
    @recipe =
      Recipe.new.tap do |r|
        r.errors.add(:base, e.message)
      end
  end

  # GET /recipes/archive/download
  def download_archive
    name = "Recipes_#{Time.current.strftime('%Y%m%d_%H%M%S')}.zip"
    file = Recipes::Archive.new(current_user).generate

    file_data = File.read(file.path)

    send_data file_data, filename: name, type: 'application/zip'
  ensure
    file.close!
    file.unlink
  end

  # GET /recipes/archive/upload
  def upload_archive_form; end

  # POST /recipes/archive/upload
  def upload_archive # rubocop:disable Metrics/AbcSize
    uploaded = params.require(:file)

    result = Recipes::Archive.new(current_user).restore(uploaded.tempfile)

    flash[:notice] = "Imported #{result[:created]} recipes (#{result[:skipped]} skipped)"
  rescue Recipes::Archive::Error => e
    flash[:alert] = e.message
  rescue StandardError => e
    Rails.logger.error("Recipe import error: #{e.class} - #{e.message}")
    flash[:alert] = 'An unknown error occurred during import'
  ensure
    redirect_to recipes_path
  end

  # GET /recipes or /recipes.json
  def index
    @recipes = policy_scope(Recipe).with_text(params[:query]).in_categories(params[:category_names]).sorted
  end

  # GET /recipes/1 or /recipes/1.json
  def show; end

  # GET /recipes/new
  def new
    @recipe = current_user.recipes.new
  end

  # GET /recipes/1/edit
  def edit; end

  # POST /recipes or /recipes.json
  def create
    @recipe = current_user.recipes.new(recipe_params)

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
    @recipe.destroy
    @recipe.image.purge
    respond_to do |format|
      format.html { redirect_to recipes_url, notice: 'Recipe was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def toggle_favorite
    @recipe.toggle!(:is_favorite) # rubocop:disable Rails/SkipsModelValidations
    render json: { is_favorite: @recipe.is_favorite }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_recipe
    @recipe = authorize Recipe.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def recipe_params
    params.require(:recipe).permit(:name, :ingredients, :directions, :yield, :prep_time, :cook_time, :description,
                                   :rating, :is_favorite, :notes, :source, :image_src, category_names: [])
  end
end
