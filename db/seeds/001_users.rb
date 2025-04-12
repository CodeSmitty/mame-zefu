# db/seeds.rb
exit unless Rails.env.development?

User.find_or_initialize_by(email: 'admin@example.com').update(password: 'password')

puts 'Seed data for users created successfully!'
