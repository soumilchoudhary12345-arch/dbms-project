require "test_helper"

class QuestionAttemptTest < ActiveSupport::TestCase
  test "a question can only be attempted once per session" do
    question = Question.create!(subject: "Mathematics", q_type: "mcq", marks: 1,
                                difficulty: "easy", body: "1 + 1?",
                                options: { "A" => "1", "B" => "2" }, answer: "B")
    session = QuizSession.create!(status: QuizSession::IN_PROGRESS, time_limit_seconds: 60,
                                  total_questions: 1, difficulty_mix: '{"easy":1}')
    session.question_attempts.create!(question: question)

    duplicate = QuestionAttempt.new(quiz_session: session, question: question)
    assert_not duplicate.valid?
    assert duplicate.errors[:question_id].present?

    # The unique index on (quiz_session_id, question_id) enforces it too.
    assert_raises ActiveRecord::RecordNotUnique do
      QuestionAttempt.new(quiz_session: session, question: question).save!(validate: false)
    end

    # A different session may attempt the same question again.
    other = QuizSession.create!(status: QuizSession::IN_PROGRESS, time_limit_seconds: 60,
                                total_questions: 1, difficulty_mix: '{"easy":1}')
    assert other.question_attempts.create!(question: question).persisted?
  end
end
