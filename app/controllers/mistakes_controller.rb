class MistakesController < ApplicationController
  before_action :set_question, only: %i[resolve reopen]

  def index
    base = QuestionAttempt.missed_by(current_user)
                          .joins(:question)
                          .includes(:question)
                          .order("question_attempts.created_at DESC").to_a

    @miss_counts = base.group_by(&:question_id).transform_values(&:size)
    @resolved_count = base.select(&:resolved?).map(&:question_id).uniq.size
    @total_open = base.reject(&:resolved?).map(&:question_id).uniq.size

    view = params[:view] == "resolved" ? base.select(&:resolved?) : base.reject(&:resolved?)
    @topics = view.map { |a| a.question.topic.presence }.compact.uniq.sort
    view = view.select { |a| a.question.topic == params[:topic] } if params[:topic].present?

    # One entry per question — the latest attempt.
    @attempts = view.uniq(&:question_id)
  end

  # "I've got this now" — archives every miss of that question (future misses re-open it).
  def resolve
    QuestionAttempt.missed_by(current_user)
                   .where(question_id: @question.id, resolved_at: nil)
                   .update_all(resolved_at: Time.current, updated_at: Time.current)
    redirect_back fallback_location: mistakes_path, notice: "Marked as understood."
  end

  # Undo a premature "understood".
  def reopen
    QuestionAttempt.missed_by(current_user)
                   .where(question_id: @question.id)
                   .where.not(resolved_at: nil)
                   .update_all(resolved_at: nil, updated_at: Time.current)
    redirect_back fallback_location: mistakes_path, notice: "Back in the mistake book."
  end

  private

  def set_question
    @question = Question.find(params[:question_id])
  end
end
