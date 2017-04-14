Rails.application.routes.draw do
  get '/invite/:invite_hash', to: 'invitation#invite', as: 'invite'

  resources :events do
    get '/albums', to: redirect('/events/%{event_id}/')
    resources :albums
  end
  get '/dashboard', to: 'events#index'

  devise_for :users,
             controllers: { omniauth_callbacks: 'users/omniauth_callbacks' },
             skip: [:sessions, :registration]

  devise_scope :users do
    delete '/users/sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  put '/set-tz', to: 'application#set_time_zone'

  root to: 'static#index'
end
