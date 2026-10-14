require "test_helper"

class TodosStreamTest < ActionDispatch::IntegrationTest
  TURBO = "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
  CHROME = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

  setup do
    post "/auth/demo"
    @headers = { "User-Agent" => CHROME, "Accept" => TURBO }
    @user = User.find_by!(email: "demo@demo.local")
    @user.todos.destroy_all
  end

  test "toggling done answers with a turbo stream, not a redirect" do
    todo = @user.todos.create!(title: "Revise integrals")

    patch todo_path(todo), params: { todo: { done: "1" } }, headers: @headers

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match(/<turbo-stream[^>]+action="replace"/, response.body)
    assert_match(/target="checklist"/, response.body)
    assert_match(/line-through/, response.body)
    assert todo.reload.done
  end

  test "adding a task streams back the updated checklist" do
    post todos_path, params: { todo: { title: "Solve chapter 5" } }, headers: @headers

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match(/Solve chapter 5/, response.body)
    assert_match(/0\/1 done/, response.body)
  end

  test "deleting a task streams back the updated checklist" do
    todo = @user.todos.create!(title: "Old task")

    delete todo_path(todo), headers: @headers

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    refute_match(/Old task/, response.body)
    assert_empty @user.todos.reload
  end

  test "plain html still falls back to a redirect for no-JS clients" do
    todo = @user.todos.create!(title: "No JS")

    patch todo_path(todo), params: { todo: { done: "1" } },
          headers: { "User-Agent" => CHROME, "Accept" => "text/html" }

    assert_response :redirect
    assert todo.reload.done
  end
end
