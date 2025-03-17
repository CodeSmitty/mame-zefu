FactoryBot.define do
  sequence :email do |n|
    base_email = ENV['TEST_SENDER_EMAIL'] || "user#{n}@gmail.com"
    base_email
  end

  factory :user do
    email { generate(:email) }
    password { 'password' }
  end
end
