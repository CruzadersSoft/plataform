require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "display_name falls back to email address" do
    user = User.new(name: nil, email_address: "volunteer@example.com")

    assert_equal "volunteer@example.com", user.display_name
  end
end
