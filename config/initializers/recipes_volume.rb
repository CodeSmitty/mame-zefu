module Recipes
  Volume = Measured.build do
    unit :tsp, aliases: %i[teaspoon tspn teaspoons]

    unit :tbsp, value: "3 tsp", aliases: %i[tablespoon tbspn tablespoons]
    unit :cup,  value: "16 tbsp", aliases: %i[cups]
    unit :pt,   value: "2 cup", aliases: %i[pint pints]
    unit :qt,   value: "2 pt", aliases: %i[quart quarts]
    unit :gal,  value: "4 qt", aliases: %i[gallon gallons]
  end
end