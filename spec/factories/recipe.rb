FactoryBot.define do
  factory :recipe do
    sequence(:name) { |n| "Recipe ##{n}" }
    user

    trait :with_category do
      transient do
        category_count { 1 }
      end

      after(:create) do |recipe, evaluator|
        create_list(:category, evaluator.category_count).each do |category|
          recipe.categories << category
        end
      end
    end
  end
end
