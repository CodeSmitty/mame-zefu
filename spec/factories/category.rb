FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category ##{n}" }
    user
  end
end
