require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "platform admin signs in to platform dashboard" do
    post session_path, params: { email_address: users(:platform_admin).email_address, password: "password" }

    assert_redirected_to platform_root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "destroy clears active church from browser session" do
    sign_in_to_church_as users(:one), churches(:grace)

    delete session_path

    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to root_path

    follow_redirect!
    assert_redirected_to onboarding_path
  end
end
