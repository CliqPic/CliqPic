Rails.application.routes.draw do
  mount ForestLiana::Engine => '/forest'
  get '/invite/:invite_hash', to: 'invitation#invite', as: 'invite'

  resources :events do
    get '/albums', to: redirect('/events/%{event_id}/')
    resources :albums do
      put '/reorder', to: 'albums#reorder_image', as: 'reorder_image', on: :member
      put '/recolor', to: 'albums#recolor_image', as: 'recolor_image', on: :member
    end
  end

  get '/dashboard', to: 'events#index'
  get '/users', to: redirect('/')
  get '/users/sign_in', to: redirect('/')
  
  devise_for :users,
             controllers: { omniauth_callbacks: 'users/omniauth_callbacks' },
             skip: [:registration]

  put '/set-tz', to: 'application#set_time_zone'

  root to: 'static#index'
end
