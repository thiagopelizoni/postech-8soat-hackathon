Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  root to: redirect('/api-docs')

  namespace :api do
    namespace :v1 do
      resources :clientes, only: %i[index show create update]
    end
  end
end
