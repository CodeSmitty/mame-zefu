Rails.application.routes.draw do
  resources :passwords, only: [:create, :new]
  resource :session, only: [:create]

  resources :users, only: [:create] do
    resource :password, only: [:edit, :update]
  end

  get '/sign_in' => 'sessions#new', as: 'sign_in'
  delete '/sign_out' => 'sessions#destroy', as: 'sign_out'
  get '/sign_up' => 'users#new', as: 'sign_up'

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
