Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that Rails uses for uptime monitoring
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  
  # Health check endpoint
  get '/health', to: 'hello#health'
  
  # Hello World endpoint
  get '/hello', to: 'hello#hello'
  
  # Redis test endpoint
  get '/redis', to: 'hello#redis_test'
  
  # Prometheus metrics endpoint
  get '/metrics', to: 'hello#metrics'
  
  # Root endpoint
  root 'hello#hello'
end
