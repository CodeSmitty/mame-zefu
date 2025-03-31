# db/seeds.rb
exit unless Rails.env.development?

admin = User.find_or_initialize_by(email: 'admin@example.com')
admin.password = 'password'
admin.save!(validate: false)

puts 'Seed data for users created successfully!'
