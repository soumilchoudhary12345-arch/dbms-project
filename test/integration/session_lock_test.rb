require "test_helper"

class SessionLockTest < ActionDispatch::IntegrationTest
  CHROME = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

  setup do
    post "/auth/demo"
    @headers = { "User-Agent" => CHROME }
    @user = User.find_by!(email: "demo@demo.local")
    QuizSession.where(user: @user, status: QuizSession::IN_PROGRESS).destroy_all
  end

  test "browsing anywhere redirects back to the active session" do
    session = QuizSession.build_session(level: QuizSession.level_for(@user), user: @user)

    %w[/ /notes /books /mistakes /questions /themes].each do |path|
      get path, headers: @headers
      assert_redirected_to session_path(session), "expected #{path} to bounce to the session"
    end
  end

  test "session page itself stays reachable" do
    session = QuizSession.build_session(level: QuizSession.level_for(@user), user: @user)
    get session_path(session), headers: @headers
    assert_response :success
    assert_select "div[data-controller=?]", "lock"
    assert_select "meta[name=?][content=?]", "turbo-cache-control", "no-cache"
  end

  test "sign out stays reachable while locked" do
    QuizSession.build_session(level: QuizSession.level_for(@user), user: @user)
    delete signout_path, headers: @headers
    assert_redirected_to signin_path
  end

  test "submitting releases the lock" do
    session = QuizSession.build_session(level: QuizSession.level_for(@user), user: @user)
    post submit_session_path(session), headers: @headers
    assert_response :redirect

    get mistakes_path, headers: @headers
    assert_response :success
    get root_path, headers: @headers
    assert_response :success
  end

  test "no session means no redirects" do
    get root_path, headers: @headers
    assert_response :success
    get questions_path, headers: @headers
    assert_response :success
  end
end
