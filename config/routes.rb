Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'data_mappers#index'
  resources :data_mappers
  resources :workflows, only: [:index]
  resources :ingests, only: [:index, :show, :destroy]
  resources :transfers, only: [:index, :show, :destroy]
  resources :reviews, only: [:index, :show, :destroy]
  
  resources :retry_ingest, only: [:show] do
    get ":id", to: "ingests#retry_ingest", on: :collection
  end
  resources :retry_transfer, only: [:show] do
    get ":id", to: "transfers#retry_transfer", on: :collection
  end
  resources :retry_review, only: [:show] do
    get ":id", to: "reviews#retry_review", on: :collection
  end
  resources :notifications

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
