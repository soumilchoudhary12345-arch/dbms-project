class SessionsController < ApplicationController
  before_action :set_session, only: %i[show submit result]

  def create
    session = QuizSession.build_session(level: current_level, user: current_user)
    redirect_to session_path(session)
  end

  # Mistake book: practice a single missed question again.
  def retry_question
    session = QuizSession.build_retry(Question.find(params[:question_id]), user: current_user)
    redirect_to session_path(session)
  end

  def show
    redirect_to result_session_path(@session) if @session.finished?
  end

  def submit
    @session.submit!(params[:answers]) if @session.active?
    redirect_to result_session_path(@session)
  end

  def result
    redirect_to questions_path unless @session.finished?
    @attempts = @session.question_attempts.includes(:question)
  end

  private

  def set_session
    @session = QuizSession.find(params[:id])
  end

  def current_level
    QuizSession.level_for(current_user)
  end
end
