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
    get 'archive/download', on: :collection, action: :download_archive
    get 'archive/upload', on: :collection, action: :upload_archive_form
    post 'archive/upload', on: :collection, action: :upload_archive
  end

  root 'recipes#index'
  resources :recipes do
    member do
      post :toggle_favorite
      delete :image, action: :delete_image
    end
  end

  get '*unmatched_route', to: 'application#not_found', constraints: lambda { |req|
    req.path.exclude? 'rails/active_storage'
  }
end
