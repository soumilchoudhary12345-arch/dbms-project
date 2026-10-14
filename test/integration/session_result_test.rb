require "test_helper"

class SessionResultTest < ActionDispatch::IntegrationTest
  CHROME = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

  setup do
    post "/auth/demo"
    @headers = { "User-Agent" => CHROME }
    @user = User.find_by!(email: "demo@demo.local")
    QuizSession.where(user: @user).destroy_all
    # The fixture bank only has two questions — give the builder a full deck.
    6.times do |i|
      Question.create!(subject: "Mathematics", q_type: "mcq", marks: 1, difficulty: "medium",
                       body: "Generated question #{i}?", answer: "A",
                       options: { "A" => "1", "B" => "2", "C" => "3", "D" => "4" })
    end
  end

  test "result separates wrong attempts from questions left blank" do
    session = QuizSession.build_session(level: QuizSession.level_for(@user), user: @user)
    attempts = session.question_attempts.includes(:question).to_a
    assert attempts.size >= 3, "need at least 3 attempts for this test"

    answers = {}
    attempts.each_with_index do |attempt, i|
      correct = attempt.question.answer
      case i
      when 1
        answers[attempt.question_id.to_s] = attempt.question.options_hash.keys.find { |l| l != correct }
      when 2
        # left blank on purpose
      else
        answers[attempt.question_id.to_s] = correct
      end
    end
    session.submit!(answers)
    assert_equal 1, session.question_attempts.where(correct: false).where.not(answer: nil).count
    assert_equal 1, session.question_attempts.where(correct: false, answer: nil).count

    get result_session_path(session), headers: @headers
    assert_response :success

    assert_select "section[aria-labelledby=?]", "wrong-heading" do
      assert_select "h2#wrong-heading", text: /Wrong answers/
      assert_select "div.rounded-lg.border.border-rose-300", 1
    end
    assert_select "section[aria-labelledby=?]", "blank-heading" do
      assert_select "h2#blank-heading", text: /Left blank/
      assert_select "div.rounded-lg.border.border-amber-300", 1
    end
    assert_select "details" do
      assert_select "div.rounded-lg.border.border-emerald-300", attempts.size - 2
    end
    refute_match(/Wrong \/ skipped/, @response.body)

    assert_select "div.text-rose-600", text: "1"
    assert_select "div.text-amber-600", text: "1"
    assert_select "div.text-emerald-600", text: (attempts.size - 2).to_s
  end

  test "perfect run shows the clean sweep note and no failure boxes" do
    session = QuizSession.build_session(level: QuizSession.level_for(@user), user: @user)
    answers = session.question_attempts.includes(:question)
                      .to_h { |a| [ a.question_id.to_s, a.question.answer ] }
    session.submit!(answers)

    get result_session_path(session), headers: @headers
    assert_response :success
    assert_match(/Perfect run/, @response.body)
    assert_select "section[aria-labelledby=?]", "wrong-heading", false
    assert_select "section[aria-labelledby=?]", "blank-heading", false
  end
end
