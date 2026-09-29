class SessionsController < ApplicationController
  before_action :set_session, only: %i[show submit result]

  def create
    session = QuizSession.build_session(level: current_level, user: current_user)
    redirect_to session_path(session)
  end

  def show
    redirect_to result_session_path(@session) if @session.finished?
  end

  def submit
    if @session.active?
      @session.question_attempts.includes(:question).each do |attempt|
        attempt.grade!(params.dig(:answers, attempt.question_id.to_s))
      end
      @session.update!(status: "finished", submitted_at: Time.current,
                       correct_count: @session.question_attempts.where(correct: true).count)
    end
    redirect_to result_session_path(@session)
  end

  def result
    redirect_to questions_path unless @session.finished?
    @attempts = @session.question_attempts.includes(:question)
    @accuracy_history = QuizSession.where(status: "finished")
                                   .order(:submitted_at).pluck(:correct_count, :time_limit_seconds)
  end

  private

  def set_session
    @session = QuizSession.find(params[:id])
  end

  def current_level
    recent = QuizSession.where(user: current_user, status: "finished")
                        .order(submitted_at: :desc).limit(5)
    answered = QuestionAttempt.where(quiz_session: recent).count
    return "medium" if answered.zero?

    accuracy = recent.sum(:correct_count).to_f / answered
    return "easy" if accuracy < 0.5
    return "hard" if accuracy >= 0.8

    "medium"
  end
end
