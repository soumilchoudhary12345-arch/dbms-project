Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "signin", to: "auth#new", as: :signin
  post "auth/:provider", to: "auth#create", as: :auth_provider,
       constraints: { provider: /google|apple|facebook|microsoft/ }
  delete "signout", to: "auth#destroy", as: :signout

  root "books#index"

  get "books/:subject",
      to: "books#show",
      as: :book_subject,
      constraints: { subject: /[^\/]+/ }

  get "notes", to: "notes#index", as: :notes

  get "notes/:subject",
      to: "notes#show",
      as: :note_subject,
      constraints: { subject: /[^\/]+/ }

  get "questions", to: "questions#show", as: :questions

  post "sessions", to: "sessions#create", as: :quiz_sessions
  get "sessions/:id", to: "sessions#show", as: :session
  post "sessions/:id/submit", to: "sessions#submit", as: :submit_session
  get "sessions/:id/result", to: "sessions#result", as: :result_session

  get "customizations", to: "customizations#show", as: :customizations

  get "pdf/:kind/:subject/:number(/:part)",
      to: "pdfs#show",
      as: :chapter_pdf,
      defaults: { part: 1 },
      constraints: { kind: /books|notes/, subject: /[^\/]+/, number: /\d+/, part: /\d+/ }
end
