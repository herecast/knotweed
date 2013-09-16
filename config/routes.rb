Knotweed::Application.routes.draw do
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  authenticated :user do
    root :to => 'contents#index'
  end
  root :to => "contents#index"
  devise_for :users
  resources :users
  
  resources :contents, only: ["show", "index"]

  namespace :custom_admin do
    resources :contents, except: ["show"]
  end
end
