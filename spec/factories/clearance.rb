FactoryBot.define do
  sequence :email do |n|
    "user#{n}@example.com"
  end

  factory :user do
    email { generate(:email) }
    password { 'password' }
  end
end

FactoryBot.define do
  sequence :name do |n|
    "chicken#{n}"
  end

  factory :recipe do
    name { :name }
    user { :user }
  end
end
