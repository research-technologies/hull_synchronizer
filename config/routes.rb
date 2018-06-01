Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'data_mappers#index'
  resources :data_mappers

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
