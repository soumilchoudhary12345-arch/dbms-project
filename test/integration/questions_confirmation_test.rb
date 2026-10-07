require "test_helper"

class QuestionsConfirmationTest < ActionDispatch::IntegrationTest
  CHROME = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

  setup do
    post "/auth/demo"
    @headers = { "User-Agent" => CHROME }
  end

  test "questions page asks for confirmation with a level preview" do
    get "/questions", headers: @headers
    assert_response :success

    assert_select "div[data-controller=?]", "confirm"
    assert_select "dialog[data-confirm-target=?]", "dialog"
    assert_select "h2", text: /Are you sure you want to begin the quiz session\?/
    assert_select "button[data-action=?]", "confirm#accept"
    assert_select "button[data-action=?]", "confirm#cancel"
    assert_match(/10 questions\s*·\s*\S+.*level\s*·\s*about \d+ minutes/, @response.body)
    assert_match(/Mix: \d+ (easy|medium|hard|super hard)/, @response.body)
  end

  test "start button still submits a session without JavaScript" do
    assert_difference -> { QuizSession.count }, 1 do
      post "/questions/sessions", headers: @headers
    end
    assert_response :redirect
  end

  test "level preview matches the level used to build the session" do
    user = User.find_by!(email: "demo@demo.local")
    level = QuizSession.level_for(user)
    get "/questions", headers: @headers
    assert_match level.tr("_", " ").capitalize, @response.body
  end
end
