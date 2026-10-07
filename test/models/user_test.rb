require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "duplicate email is rejected, stored lowercased" do
    assert_difference -> { User.count }, 1 do
      User.create!(name: "Ada", email: "  Duplicate@Example.COM ", provider: "demo")
    end
    assert_equal "duplicate@example.com", User.find_by!(name: "Ada").email

    duplicate = User.new(name: "Grace", email: "duplicate@example.com", provider: "google_oauth2")
    assert_not duplicate.valid?
    assert duplicate.errors[:email].present?

    # The unique index enforces it even if validations are skipped
    # (the value is already lowercase, exactly as the DB stores it).
    assert_raises ActiveRecord::RecordNotUnique do
      User.new(name: "Grace", email: "duplicate@example.com", provider: "demo").save!(validate: false)
    end
  end
end
