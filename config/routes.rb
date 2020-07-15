Rails.application.routes.draw do
  get '/saml/auth' => 'saml_idp#new'
  post '/saml/auth' => 'saml_idp#create'
end
