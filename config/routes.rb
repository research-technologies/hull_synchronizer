Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'data_mappers#index'
  resources :data_mappers
  resources :workflows, only: [:index]
  resources :ingests, only: [:index, :show, :destroy, :update]
  resources :transfers, only: [:index, :show, :destroy, :update]
  resources :reviews, only: [:index, :show, :destroy, :update]
  resources :retry_ingest do
    get ":id", to: "ingests#retry", on: :collection
  end
  resources :retry_transfer do
    get ":id", to: "transfers#retry", on: :collection
  end
  resources :retry_review do
    get ":id", to: "reviews#retry", on: :collection
  end
  resources :notifications

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
