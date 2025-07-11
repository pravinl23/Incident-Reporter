require 'sidekiq/web'

Rails.application.routes.draw do
  # Mount Sidekiq web UI for monitoring
  mount Sidekiq::Web => '/sidekiq'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Incident routes
  resources :incidents do
    member do
      get 'replay'
      post 'analyze_message'
      post 'clear_suggestions'
      get 'suggestions'
    end
  end
  
  # Suggestion routes
  resources :suggestions, only: [] do
    member do
      post 'update_status'
    end
  end

  # Defines the root path route ("/")
  root "incidents#index"
end
