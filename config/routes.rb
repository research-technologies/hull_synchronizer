Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'data_mappers#index'
  resources :data_mappers
  resources :ingests, only: [:index, :show, :destroy, :update]
  resources :retry do
    get ":id", to: "ingests#retry", on: :collection
  end
  resources :notifications

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
