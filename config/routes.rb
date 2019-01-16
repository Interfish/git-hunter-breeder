Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'tagger#query'
  get 'tag', to: 'tagger#index'
  post '/', to: 'tagger#tag'
end