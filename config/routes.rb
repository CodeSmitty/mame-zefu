Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get 'health_check', to: 'application#health_check'

  resources :recipes do
    get 'web_search', on: :collection
    get 'web_result', on: :collection
  end

  root 'recipes#index'
  resources :recipes do
    member do
      post :toggle_favorite
    end
  end
end
