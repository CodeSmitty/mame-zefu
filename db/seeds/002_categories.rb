# db/seeds.rb
exit unless Rails.env.development?

categories_data = [
  { name: 'Appetizer' },
  { name: 'Main' },
  { name: 'Side' },
  { name: 'Dessert' },
  { name: 'Soup' },
  { name: 'Salad' },
  { name: 'Sandwich' },
  { name: 'Beverage' },
  { name: 'Bread' },
  { name: 'Pasta' },
  { name: 'Fruit' },
  { name: 'Vegetable' },
  { name: 'Seafood' },
  { name: 'Poultry' },
  { name: 'Beef' },
  { name: 'Pork' },
  { name: 'Sauce' },
  { name: 'Condiment' }
]

categories_data.each do |category_data|
  Category.find_or_create_by(name: category_data[:name]).update(category_data)
end

puts 'Seed data for categories created successfully!'
