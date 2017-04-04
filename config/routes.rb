Rails.application.routes.draw do
  resources :events do
    get '/albums', to: redirect('/events/%{event_id}/')
    resources :albums
  end
  get '/dashboard', to: 'events#index'

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'static#index'
end
