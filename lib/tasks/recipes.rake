namespace :recipes do
  desc "Import recipes from a file"
  task :import, [:file] => :environment do |t, args|
    require 'nokogiri'

    file = Rails.root.join args.file
    contents = File.read(file)

    document = Nokogiri::HTML(contents)

    document.css('.recipe-details').each do |doc|
      Recipe.find_or_initialize_by(name: doc.css('[itemprop="name"]').text).tap do |r|
        puts doc.css('[itemprop="recipeYield"]').text
        puts doc.css('[itemprop="prepTime"]').xpath('preceding-sibling::span').text
        puts doc.css('[itemprop="cookTime"]').xpath('preceding-sibling::span').text
        r.ingredients = doc.css('[itemprop="recipeIngredients"]').text.gsub(/\A\s+|\s+\Z/, '').gsub(/^ +| +$/, '')
        r.directions = doc.css('[itemprop="recipeDirections"]').text.gsub(/\A\s+|\s+\Z/, '').gsub(/^ +| +$/, '')
        puts doc.css('[itemprop="recipeNotes"]').text.gsub(/\A\s+|\s+\Z/, '').gsub(/^ +| +$/, '')
        puts doc.css('[itemprop="recipeRating"]').attribute('content')
        puts doc.css('[itemprop="recipeIsFavourite"]').attribute('content')
        doc.css('[itemprop="recipeCourse"]').each do |elem|
          puts elem.attribute('content')
        end
        doc.css('[itemprop="recipeCategory"]').each do |elem|
          puts elem.attribute('content')
        end
        doc.css('[itemprop="recipeCollection"]').each do |elem|
          puts elem.attribute('content')
        end
      end.save
    end
  end
end
