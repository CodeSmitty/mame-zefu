# db/seeds.rb
categories_data = [
  { name: 'Appetizer' },
  { name: 'Beef' },
  { name: 'Beverage' },
  { name: 'Bread' },
  { name: 'Condiment' },
  { name: 'Dessert' },
  { name: 'Fruit' },
  { name: 'Main' },
  { name: 'Pasta' },
  { name: 'Pork' },
  { name: 'Poultry' },
  { name: 'Salad' },
  { name: 'Sandwich' },
  { name: 'Sauce' },
  { name: 'Seafood' },
  { name: 'Side' },
  { name: 'Soup' },
  { name: 'Vegetable' }
]


categories_data.each do |category_data|
  Category.find_or_create_by(name: category_data[:name])
end

puts 'Seed data for categories created successfully!'
