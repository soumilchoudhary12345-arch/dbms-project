class BooksController < ApplicationController
  def index
    @subjects = ContentLibrary.subjects
    @recommended = recommended_books
  end

  def show
    @subject = ContentLibrary.find_subject(params[:subject])
    render_not_found unless @subject
  end

  private

  def recommended_books
    catalog = YAML.load_file(Rails.root.join("config/books.yml"))
    catalog.fetch(recent_subject_key(catalog), [])
  end

  def recent_subject_key(catalog)
    last = QuizSession.where(user: current_user).order(created_at: :desc).first
    subject = last&.questions&.first&.subject.to_s.downcase
    catalog.key?(subject) ? subject : catalog.keys.first
  end

  def render_not_found
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
end
