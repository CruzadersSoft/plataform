require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    assert_not ActiveRecord::Base.connection.data_source_exists?(:sessions)

    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
  end

  test "platform admin signs in to platform dashboard" do
    post session_path, params: { email_address: users(:platform_admin).email_address, password: "password" }

    assert_redirected_to platform_root_path
    assert_equal users(:platform_admin).id, session[:user_id]
  end

  test "regular user is not returned to platform area after signing in" do
    get platform_root_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:two).email_address, password: "password" }

    assert_redirected_to root_path
    follow_redirect!
    assert_redirected_to onboarding_path
    follow_redirect!
    assert_response :success
    assert_select ".alert", text: /Voce nao tem permissao/, count: 0
  end

  test "platform admin can return to requested platform area after signing in" do
    get platform_root_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:platform_admin).email_address, password: "password" }

    assert_redirected_to platform_root_path
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil session[:user_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_nil session[:user_id]
  end

  test "signing in again restores the user's single active church" do
    sign_in_to_church_as users(:one), churches(:grace)

    delete session_path

    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to root_path

    follow_redirect!
    assert_response :success
    assert_select "h1", churches(:grace).name
    assert_select "[data-testid='current-church-slug']", churches(:grace).slug
  end

  test "stale selected church is cleared when another user signs in" do
    sign_in_to_church_as users(:one), churches(:grace)
    delete session_path

    post session_path, params: { email_address: users(:two).email_address, password: "password" }
    assert_redirected_to root_path

    follow_redirect!
    assert_redirected_to onboarding_path
    assert_nil session[:church_id]
  end
end
