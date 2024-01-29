Rails.application.routes.draw do
  resources :recipes, :categories
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'recipes#index'
end
