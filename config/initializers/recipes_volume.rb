module Recipes
  Volume = Measured.build do
    unit :tsp, aliases: %i[teaspoon tspn teaspoons]

    unit :tbsp, value: "3 tsp", aliases: %i[tablespoon tbspn tablespoons]
    unit :cup,  value: "16 tbsp", aliases: %i[cups cup]
    unit :pt,   value: "2 cup", aliases: %i[pint pints]
    unit :qt,   value: "2 pt", aliases: %i[quart quarts]
    unit :gal,  value: "4 qt", aliases: %i[gallon gallons]
  end

  Weight = Measured.build do
    unit :g, aliases: %i[gram grams]
    unit :kg, value: "1000 g", aliases: %i[kilogram kilograms kg]
    unit :oz, value: "28.3495 g", aliases: %i[ounce ounces oz]
    unit :lb, value: "16 oz", aliases: %i[pound pounds lb lbs]
  end
end