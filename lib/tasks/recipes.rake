# frozen_string_literal: true

namespace :recipes do # rubocop:disable Metrics/BlockLength
  task export: :environment do
    filename = Rails.root.join "Recipes_#{Time.current.strftime('%Y%m%d_%H%M%S')}.zip"
    user = User.find_by(email: 'admin@example.com')

    puts "Exporting recipes to #{filename}..."

    file = Recipes::Archive.new(user).generate
    FileUtils.mv(file.path, filename)
  end

  task :import, [:file] => :environment do |_, args|
    filename = Rails.root.join args.file
    user = User.find_by(email: 'admin@example.com')

    result = { created: 0, skipped: 0 }

    File.open(filename, 'rb') do |file|
      puts "Importing recipes from #{filename}..."
      result = Recipes::Archive.new(user).restore(file)
    end

    puts "Imported #{result[:created]} recipes (#{result[:skipped]} skipped)"
  end

  namespace :import do
    desc 'Import recipes from a Recipe Keeper export ZIP file'
    task :recipe_keeper, [:file] => :environment do |_, args|
      filename = Rails.root.join args.file
      user = User.find_by(email: 'admin@example.com')

      result = { created: 0, skipped: 0 }

      File.open(filename, 'rb') do |file|
        puts "Importing recipes from #{filename}..."
        result = Recipes::Archive::RecipeKeeper.new(user).restore(file)
      end

      puts "Imported #{result[:created]} recipes (#{result[:skipped]} skipped)"
    end
  end
end
