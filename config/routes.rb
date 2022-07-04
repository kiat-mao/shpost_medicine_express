Rails.application.routes.draw do
  resources :expresses
  root 'welcome#index'
  
  devise_for :users, controllers: { sessions: "users/sessions" }

  resources :user_logs, only: [:index, :show, :destroy]

  resources :units do
    collection do
      get 'import'
      post 'import' => 'units#import'
    end
    resources :users, :controller => 'users'

    member do 
      # get 'index'
      get 'new_child_unit' => 'units#new'
      get 'child_units' => 'units#index'
      # get 'update_unit'
      # get 'destroy_unit'
    end
  end

  resources :users do
    member do
      get 'reset_pwd' => 'users#to_reset_pwd'
      patch 'reset_pwd' => 'users#reset_pwd'
      post 'lock' => 'users#lock'
      post 'unlock' => 'users#unlock'
    end
    resources :roles, :controller => 'user_roles'
  end

  resources :up_downloads do
    collection do 
      get 'up_download_import'
      post 'up_download_import' => 'up_downloads#up_download_import'
      
      get 'to_import'
      
      
    end
    member do
      get 'up_download_export'
      post 'up_download_export' => 'up_downloads#up_download_export'
    end
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
