Rails.application.routes.draw do
  resources :users, only: [:index, :show, :create]
  
  # Coloque a rota do histórico ANTES do resources
  get '/messages/:user_id/:recipient_id', to: 'messages#index'
  
  resources :messages, only: [:index, :create]
  
  mount ActionCable.server => '/cable'
end