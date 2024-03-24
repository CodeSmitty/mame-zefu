namespace :recipes do
  desc 'Import recipes from a file'
  task :import, [:file] => :environment do |_, args|
    require 'nokogiri'

    file = Rails.root.join args.file
    contents = File.read(file)
    document = Nokogiri::HTML(contents)
    document.css('.recipe-details').each do |doc|
      Recipe.find_or_initialize_by(name: doc.css('[itemprop="name"]').text).tap do |r|
        r.yield = doc.css('[itemprop="recipeYield"]').text
        r.prep_time = doc.css('[itemprop="prepTime"]').xpath('preceding-sibling::span').text
        r.cook_time = doc.css('[itemprop="cookTime"]').xpath('preceding-sibling::span').text
        r.ingredients = doc.css('[itemprop="recipeIngredients"]').text.gsub(/\A\s+|\s+\Z/, '').gsub(/^ +| +$/, '')
        r.directions = doc.css('[itemprop="recipeDirections"]').text.gsub(/\A\s+|\s+\Z/, '').gsub(/^ +| +$/, '')
        r.notes = doc.css('[itemprop="recipeNotes"]').text.gsub(/\A\s+|\s+\Z/, '').gsub(/^ +| +$/, '')
        r.rating = doc.css('[itemprop="recipeRating"]').attribute('content').to_s
        r.is_favorite = doc.css('[itemprop="recipeIsFavourite"]').attribute('content').to_s == 'True'
        @category_names = []
        doc.css('[itemprop="recipeCourse"]').each { |elem| @category_names << elem.text }
        doc.css('[itemprop="recipeCategory"]').each { |elem| @category_names << elem.attribute('content').to_s }
        doc.css('[itemprop="recipeCollection"]').each { |elem| @category_names << elem.attribute('content').to_s }
        r.category_names = @category_names.select(&:present?)
      end.save
    end
  end
end
