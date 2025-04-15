require 'sidekiq/web'

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount Sidekiq::Web => '/sidekiq'

  root to: redirect('/api-docs')

  resources :clientes, only: %i[index show create update]
  post 'login', to: 'clientes#login'

  resources :videos, only: %i[index show create update destroy]
end
