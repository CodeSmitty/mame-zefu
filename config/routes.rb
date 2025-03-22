Rails.application.routes.draw do
  resources :passwords, controller: 'clearance/passwords', only: [:create, :new]
  resource :session, controller: 'clearance/sessions', only: [:create]

  resources :users, controller: 'clearance/users', only: [:create] do
    resource :password, controller: 'clearance/passwords', only: [:edit, :update]
  end

  get '/sign_in' => 'clearance/sessions#new', as: 'sign_in'
  delete '/sign_out' => 'clearance/sessions#destroy', as: 'sign_out'
  get '/sign_up' => 'clearance/users#new', as: 'sign_up'

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
