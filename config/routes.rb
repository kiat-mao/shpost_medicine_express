Rails.application.routes.draw do
  scope 'shangyao' do
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

  resources :packages do
    collection do 
      get 'scan'
      post 'scan'
      get 'find_bag_result'
      post 'find_bag_result'
      post 'do_packaged'
      get 'tkzd'
      post 'tkzd'
      get 'zxqd'
      post 'zxqd'
      get 'send_sy'
      post 'send_sy'
      post 'package_export'
      get 'gy_scan'
      post 'gy_scan'
      get 'gy_find_bag_result'
      post 'gy_find_bag_result'
      post 'gy_do_packaged'
      get 'send_finish'
      post 'send_finish'
      # get 'index'
      # post 'index'
    end
    member do
      get 'cancelled'
      get 'send_xyd'
    end
  end

  resources :orders do
    collection do 
      get 'other_province_index'
      get 'order_report'
      post 'order_report'
      post 'order_report_export'
      get 'set_no_modify'
      post 'set_no_modify'
    end
  end



  match "/standard_interface/order_push" => "standard_interface#order_push", via: [:get, :post]
  end
end
