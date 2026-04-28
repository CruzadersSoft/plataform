require "test_helper"

class Platform::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "platform admin can access platform dashboard without current church" do
    sign_in_as users(:platform_admin)

    get platform_root_path

    assert_response :success
  end

  test "regular user cannot access platform dashboard" do
    sign_in_as users(:two)

    get platform_root_path

    assert_redirected_to root_path
  end

  test "regular user denied from platform dashboard does not see permission alert" do
    sign_in_as users(:two)

    get platform_root_path
    follow_redirect!
    assert_redirected_to onboarding_path
    follow_redirect!

    assert_response :success
    assert_select ".alert", text: /Voce nao tem permissao/, count: 0
  end
end
