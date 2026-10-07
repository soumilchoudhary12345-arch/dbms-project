class QuestionsController < ApplicationController
  def show
    level = QuizSession.level_for(current_user)
    estimate = QuizSession.estimate_for(level)
    counts = QuizSession.mix_counts_for(level)

    @preview = {
      level_label: level.tr("_", " ").capitalize,
      questions: estimate[:questions],
      minutes: [ (estimate[:seconds].fdiv(60)).round, 1 ].max,
      mix: counts.map { |difficulty, n| "#{n} #{difficulty.tr('_', ' ')}" }.join(" · "),
      has_history: QuizSession.submitted.where(user: current_user).exists?
    }
  end
end
