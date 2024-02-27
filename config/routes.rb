Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'recipes#index'
  resources :recipes do
    member do
      post :toggle_favorite
    end
  end
end
