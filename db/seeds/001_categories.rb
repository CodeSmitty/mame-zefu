# db/seeds.rb
categories_data = [
  #group A
  { name: 'Appetizer' },

  #group B
  { name: 'Beef' },
  { name: 'Beverage' },
  { name: 'Bread' }, 
  
  #group C
  { name: 'Condiment' },
  
  #group D
  { name: 'Dessert' },

  #group F
  { name: 'Fruit' },
  
  #group M
  { name: 'Main' },

  #group P
  { name: 'Pasta' },
  { name: 'Pork' },
  { name: 'Poultry' },

  #group S
  { name: 'Salad' },
  { name: 'Sandwich' },
  { name: 'Sauce' },
  { name: 'Seafood' },
  { name: 'Side' },
  { name: 'Soup' },
  
  
  #group V
  { name: 'Vegetable' }
]


categories_data.each do |category_data|
  Category.find_or_create_by(name: category_data[:name])
end

puts 'Seed data for categories created successfully!'
