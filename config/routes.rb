Rails.application.routes.draw do
  resources :recipes
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'recipes#index'
  get 'categories', to: 'categories#create'
end
