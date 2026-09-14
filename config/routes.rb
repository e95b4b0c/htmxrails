Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Every action answers with either a full page (first visit, refresh, deep
  # link) or a bare fragment (htmx swap) depending on the HX-Request header.
  root "pages#home"

  get "about", to: "pages#about", as: :about
  get "contact", to: "pages#contact", as: :contact
  post "contact", to: "pages#create_message"

  # Polled by the clock widget on the home page.
  get "clock", to: "pages#clock", as: :clock
end
