require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  test "authenticated user without church sees onboarding" do
    sign_in_as users(:two)

    get onboarding_path

    assert_response :success
  end

  test "authenticated user with active church is redirected away from onboarding" do
    sign_in_as users(:one)

    get onboarding_path

    assert_redirected_to root_path
  end

  test "creating a church activates it for the session" do
    sign_in_as users(:two)

    post onboarding_path, params: {
      onboarding: {
        action_type: "create_church",
        church: { name: "City Church", slug: "city-church" }
      }
    }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert Church.exists?(slug: "city-church")
  end

  test "joining by invitation activates the church for the session" do
    sign_in_as users(:two)

    post onboarding_path, params: {
      onboarding: {
        action_type: "join_church",
        invitation_code: church_invitation_codes(:grace_volunteer).code
      }
    }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end
end
