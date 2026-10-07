class HomeController < ApplicationController
  def index
    @notes_chapters = ContentLibrary.subjects(root: StudyContent.notes_root).sum { |s| s.chapters.size }
    @book_chapters = ContentLibrary.subjects.sum { |s| s.chapters.size }
    @question_count = Question.count
    @todos = current_user.todos.order(:done, :id)
    @done_count = @todos.count(&:done)
    @open_mistakes = QuestionAttempt.missed_by(current_user).where(resolved_at: nil)
                                    .distinct.count(:question_id)
  end
end
