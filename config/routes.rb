Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :recipes do
    get 'import', on: :collection
    get 'from_url', on: :collection
  end

  root 'recipes#index'
  resources :recipes do
    member do
      post :toggle_favorite
    end
  end
end
