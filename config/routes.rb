Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "signin", to: "auth#new", as: :signin
  post "auth/:provider", to: "auth#create", as: :auth_provider
  get "auth/:provider/callback", to: "auth#callback", as: :auth_callback,
      constraints: { provider: /google_oauth2|microsoft_graph|facebook/ }
  get "auth/failure", to: "auth#failure", as: :auth_failure
  delete "signout", to: "auth#destroy", as: :signout

  root "home#index"

  resources :todos, only: %i[create update destroy]

  get "books", to: "books#index", as: :books

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

  # Practice sessions always live under Questions (nav + URLs stay scoped).
  scope "questions" do
    post "retry/:question_id", to: "sessions#retry_question", as: :retry_question
    post "sessions", to: "sessions#create", as: :quiz_sessions
    get "sessions/:id", to: "sessions#show", as: :session
    post "sessions/:id/submit", to: "sessions#submit", as: :submit_session
    get "sessions/:id/result", to: "sessions#result", as: :result_session
  end

  get "mistakes", to: "mistakes#index", as: :mistakes
  post "mistakes/:question_id/resolve", to: "mistakes#resolve", as: :resolve_mistake,
       constraints: { question_id: /\d+/ }
  post "mistakes/:question_id/reopen", to: "mistakes#reopen", as: :reopen_mistake,
       constraints: { question_id: /\d+/ }

  get "themes", to: "themes#show", as: :themes
  get "customizations", to: redirect("/themes")

  get "pdf/:kind/:subject/:number(/:part)",
      to: "pdfs#show",
      as: :chapter_pdf,
      defaults: { part: 1 },
      constraints: { kind: /books|notes/, subject: /[^\/]+/, number: /\d+/, part: /\d+/ }
end
