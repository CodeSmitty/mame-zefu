class RecipesController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :require_login
  before_action :ensure_extraction_enabled, only: %i[extraction_form extraction extraction_result]
  before_action :validate_image_upload, only: [:extraction]
  before_action :set_recipe, only: %i[show edit update destroy toggle_favorite delete_image]
  skip_after_action :verify_pundit_authorization, only: %i[
    web_search web_result
    download_archive upload_archive_form upload_archive
    extraction_form extraction extraction_result
    new create
  ]

  def web_search; end

  def web_result
    @recipe = Recipes::Import.new(uri: uri_from_params, force_json_schema: force_json).recipe
  rescue StandardError => e
    @recipe = Recipe.new(source: uri_from_params)

    flash.now[:alert] = 'Unable to import recipe.'

    Rails.logger.error("Recipe import error: #{e.class} - #{e.message}. Source: #{uri_from_params}")
  end

  def extraction_form; end

  def extraction
    token = Recipes::Extraction::ResultStore.store(user: current_user, recipe: extracted_recipe)

    redirect_to(
      extraction_result_recipes_path(token:),
      notice: 'Recipe extracted. Review and save.'
    )
  rescue Recipes::Extraction::Error => e
    Rails.logger.error("Recipe extraction error: #{e.class} - #{e.message}")
    flash.now[:alert] = e.message
    render :extraction_form, status: :unprocessable_content
  end

  def extraction_result
    recipe_attributes = Recipes::Extraction::ResultStore.fetch(user: current_user, token: params[:token].to_s)

    unless recipe_attributes
      redirect_to extraction_recipes_path, alert: 'Extraction result not found or expired.'
      return
    end

    @recipe = current_user.recipes.new(recipe_attributes)
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
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @recipe.errors, status: :unprocessable_content }
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
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @recipe.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /recipes/1 or /recipes/1.json
  def destroy
    @recipe.destroy
    respond_to do |format|
      format.html { redirect_to recipes_url, notice: 'Recipe was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def toggle_favorite
    @recipe.toggle!(:is_favorite) # rubocop:disable Rails/SkipsModelValidations
    render json: { is_favorite: @recipe.is_favorite }
  end

  def delete_image
    @recipe.image.purge if @recipe.image.attached?
    respond_to do |format|
      format.json { render json: { success: true } }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_recipe
    @recipe = authorize Recipe.find(params[:id])
  end

  def uri_from_params
    @uri_from_params ||= URI(params.require(:url))
  end

  def force_json
    ActiveModel::Type::Boolean.new.cast(params[:force_json])
  end

  # Only allow a list of trusted parameters through.
  def recipe_params
    params
      .require(:recipe)
      .permit(:name, :ingredients, :directions, :yield, :prep_time, :cook_time, :total_time, :description,
              :rating, :is_favorite, :notes, :source, :image, :image_src, category_names: [])
  end

  def validate_image_upload
    upload = image_upload_param
    return if upload.respond_to?(:tempfile) && upload.tempfile.respond_to?(:path)

    flash.now[:alert] = 'Image is required and must be a valid file.'
    render :extraction_form, status: :unprocessable_content
  end

  def image_upload_param
    params[:image]
  end

  def extracted_recipe
    Recipes::Extraction.from_file(image_upload_param.tempfile.path)
  end

  def ensure_extraction_enabled
    return if Recipes::Extraction.enabled?(current_user)

    redirect_to recipes_path, alert: 'Recipe extraction is not enabled.'
  end
end
