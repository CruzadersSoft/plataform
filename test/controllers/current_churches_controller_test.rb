require "test_helper"

class CurrentChurchesControllerTest < ActionDispatch::IntegrationTest
  test "changes the active church when user has membership" do
    sign_in_as users(:one)

    patch current_church_path, params: { church_id: churches(:grace).id }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "does not activate a church without membership" do
    sign_in_as users(:two)

    patch current_church_path, params: { church_id: churches(:grace).id }

    assert_redirected_to onboarding_path
  end
end
