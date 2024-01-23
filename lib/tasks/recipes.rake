# frozen_string_literal: true

namespace :recipes do # rubocop:disable Metrics/BlockLength
  task export: :environment do
    require 'zip'

    filename = Rails.root.join "Recipes_#{Time.current.strftime('%Y%m%d_%H%M%S')}.zip"
    user = User.find_by(email: 'admin@example.com')

    puts "Exporting recipes to #{filename}..."

    Zip::File.open(filename, create: true) do |zip_file|
      recipes = []
      user.recipes.each do |recipe|
        recipes << recipe.as_json(
          except: %i[id user_id created_at updated_at],
          include: { image: { only: [], methods: :filename } }
        )

        next unless recipe.image.attached?

        zip_file.get_output_stream("images/#{recipe.image.filename}") do |f|
          f.write recipe.image.download
        end
      end

      zip_file.get_output_stream('recipes.json') do |f|
        f.write JSON.pretty_generate(recipes)
      end
    end
  end

  task :import, [:file] => :environment do |_, args| # rubocop:disable Metrics/BlockLength
    require 'zip'

    filename = Rails.root.join args.file
    user = User.find_by(email: 'admin@example.com')

    Zip::File.open(filename) do |zip_file|
      contents = zip_file.glob('recipes.json').first.get_input_stream.read

      JSON.parse(contents).each do |recipe_data|
        recipe_name = recipe_data['name']

        puts "Importing: #{recipe_name}"

        if user.recipes.exists?(name: recipe_name)
          puts '..skipping, already exists'
          next
        end

        Recipe.new(recipe_data.except('image')).tap do |recipe|
          recipe.image_src = recipe_data.dig('image', 'filename')
          recipe.user = user

          if recipe.image_src.present?
            puts '..attaching image'
            image = zip_file.glob("images/#{recipe.image_src}").first
            raise 'Recipe image too large when extracted' if image.size > Recipe::MAX_IMAGE_SIZE

            recipe.image.attach(
              io: image.get_input_stream,
              filename: File.basename(recipe.image_src)
            )
          end
        end.save!
      end
    end
  end

  namespace :import do # rubocop:disable Metrics/BlockLength
    desc 'Import recipes from a Recipe Keeper export ZIP file'
    task :recipe_keeper, [:file] => :environment do |_, args| # rubocop:disable Metrics/BlockLength
      require 'nokogiri'
      require 'zip'

      filename = Rails.root.join args.file
      user = User.find_by(email: 'admin@example.com')

      recipe_class = Recipes::Import::RecipeKeeper

      Zip::File.open(filename) do |zip_file|
        contents = zip_file.glob('recipes.html').first.get_input_stream.read

        document = Nokogiri::HTML(contents)
        document.css('.recipe-details').each do |doc|
          recipe_name = recipe_class.new(doc).recipe_name

          puts "Importing: #{recipe_name}"

          if user.recipes.exists?(name: recipe_name)
            puts '..skipping, already exists'
            next
          end

          recipe_class.new(doc).recipe.tap do |recipe|
            recipe.user = user

            if recipe.image_src.present?
              puts '..attaching image'
              image = zip_file.glob(recipe.image_src).first
              raise 'Recipe image too large when extracted' if image.size > Recipe::MAX_IMAGE_SIZE

              recipe.image.attach(
                io: image.get_input_stream,
                filename: File.basename(recipe.image_src)
              )
            end
          end.save!
        end
      end
    end
  end
end
