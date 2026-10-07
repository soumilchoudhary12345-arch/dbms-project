require "test_helper"

class QuizSessionTest < ActiveSupport::TestCase
  test "generated sessions start unanswered and submit computes the score" do
    generated = QuizSession.build_session(level: "medium")
    assert_equal generated.total_questions, generated.question_attempts.count
    generated.question_attempts.each do |attempt|
      assert_nil attempt.answer
      assert_nil attempt.correct
    end

    first  = make_question("1 + 1?", "B")
    second = make_question("2 x 2?", "A")
    third  = make_question("3 x 3?", "C")

    session = QuizSession.create!(status: QuizSession::IN_PROGRESS, time_limit_seconds: 60,
                                  total_questions: 3, difficulty_mix: '{"medium":3}')
    [ first, second, third ].each { |q| session.question_attempts.create!(question: q) }

    # A freshly generated session is unanswered: answer and correct are both NULL.
    session.question_attempts.each do |attempt|
      assert_nil attempt.answer
      assert_nil attempt.correct
    end

    session.submit!({ first.id.to_s => "B", second.id.to_s => "A", third.id.to_s => "D" })

    session.reload
    assert_equal QuizSession::SUBMITTED, session.status
    assert_equal 2, session.correct_count
    assert_equal 3, session.total_questions
    assert_not_nil session.submitted_at
    assert_equal 2, session.question_attempts.where(correct: true).count
    assert_equal "D", session.question_attempts.find_by(question: third).answer
    assert session.question_attempts.find_by(question: first).reload.correct
    assert_not session.question_attempts.find_by(question: third).correct
  end

  private

  def make_question(body, answer)
    Question.create!(subject: "Mathematics", q_type: "mcq", marks: 1, difficulty: "medium",
                     body: body, options: { "A" => "1", "B" => "2", "C" => "3", "D" => "4" },
                     answer: answer)
  end
end
