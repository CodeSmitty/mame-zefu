Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  constraints Clearance::Constraints::SignedIn.new { |user| user.is_admin? } do
    mount Flipper::UI.app(Flipper) => '/admin/flipper', as: :flipper_ui
  end

  namespace :admin do
    resources :users, only: %i[index show edit update]
    resources :recipes, only: %i[index show]
    resources :categories, only: %i[index show]

    root to: 'users#index'
  end

  resources :passwords, only: %i[create new]
  resource :session, only: %i[create]

  resources :users, only: %i[create] do
    resource :password, only: %i[edit update]
  end

  get '/sign_in' => 'sessions#new', as: 'sign_in'
  delete '/sign_out' => 'sessions#destroy', as: 'sign_out'
  get '/sign_up' => 'users#new', as: 'sign_up'

  get 'health_check', to: 'application#health_check'

  resources :recipes do
    get 'web_search', on: :collection
    get 'web_result', on: :collection
    get 'extraction', on: :collection, action: :extraction_form
    post 'extraction', on: :collection, action: :extraction
    get 'extraction/result/:token', on: :collection, action: :extraction_result, as: :extraction_result
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
