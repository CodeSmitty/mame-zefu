require 'zip'

module Recipes
  class Archive
    def initialize(user)
      @user = user
    end

    def generate
      file = Tempfile.new(['recipes', '.zip'])
      file.binmode

      Zip::File.open(file.path, create: true) do |zip_file|
        recipes = export_scope.map { |recipe| export_recipe(recipe, zip_file) }

        zip_file.get_output_stream(recipe_filename) do |f|
          f.write JSON.pretty_generate(recipes)
        end
      end

      file
    end

    def restore(io)
      results = { created: 0, skipped: 0 }

      Zip::File.open_buffer(io) do |zip_file|
        entry = zip_file.glob(recipe_filename).first or raise RecipeFileMissingError

        extract_recipes(entry.get_input_stream.read).each do |recipe_data|
          import_recipe(recipe_data, zip_file).tap do |recipe|
            recipe.present? ? results[:created] += 1 : results[:skipped] += 1
          end
        end
      end

      results
    end

    private

    attr_reader :user

    def recipe_filename
      'recipes.json'
    end

    def image_path
      'images'
    end

    def export_scope
      user
        .recipes
        .includes(:categories)
        .with_attached_image
    end

    def export_recipe(recipe, zip_file)
      if recipe.image.attached?
        zip_file.get_output_stream("#{image_path}/#{recipe.image.filename}") do |f|
          f.write recipe.image.download
        end
      end

      recipe.as_json(
        except: %i[id user_id created_at updated_at],
        methods: :category_names,
        include: { image: { only: [], methods: :filename } }
      )
    end

    def extract_recipes(contents)
      JSON.parse(contents)
    end

    def import_recipe(recipe_data, zip_file)
      recipe = load_recipe(recipe_data)
      return if recipe_exists?(recipe)

      recipe.user = user
      attach_image(recipe, zip_file)

      recipe.save!
    end

    def load_recipe(recipe_data)
      Recipe.new(recipe_data.except('image')).tap do |recipe|
        image_filename = recipe_data.dig('image', 'filename')
        recipe.image_src = "#{image_path}/#{image_filename}" if image_filename.present?
      end
    end

    def recipe_exists?(recipe)
      @existing_names ||= user.recipes.pluck(:name)
      @existing_names.include?(recipe.name)
    end

    def attach_image(recipe, zip_file)
      return if recipe.image_src.blank?

      image_entry = zip_file.glob(recipe.image_src).first
      raise RecipeImageMissingError unless image_entry
      raise RecipeImageTooLargeError if image_entry.size > Recipe::MAX_IMAGE_SIZE

      recipe.image.attach(
        io: image_entry.get_input_stream,
        filename: File.basename(recipe.image_src)
      )
    end

    class Error < StandardError; end

    class RecipeFileMissingError < Error
      def initialize(msg = 'Recipe file is missing from the archive')
        super
      end
    end

    class RecipeImageMissingError < Error
      def initialize(msg = 'Recipe image is missing from the archive')
        super
      end
    end

    class RecipeImageTooLargeError < Error
      def initialize(msg = 'Recipe image too large')
        super
      end
    end
  end
end
