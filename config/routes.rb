Rails.application.routes.draw do
  resources :recipes
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'recipes#index'
  get 'categories', to: 'categories#create'
  resources :recipes do
    member do
      post :toggle_favorite
    end
  end
end
