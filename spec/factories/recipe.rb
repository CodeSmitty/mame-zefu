FactoryBot.define do
  sequence :name do |n|
    "chicken#{n}"
  end

  factory :recipe do
    name
    user
  end
end
