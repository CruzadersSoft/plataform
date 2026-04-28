require "test_helper"

class Church::MembersControllerTest < ActionDispatch::IntegrationTest
  test "church admin lists active members for the current church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get members_path

    assert_response :success
    assert_select "h1", "Membros"
    assert_select "[data-testid='member-row']", count: 3
    assert_select "td", text: users(:one).email_address
    assert_select "td", text: users(:three).email_address
  end

  test "volunteer sees their own member profile" do
    sign_in_to_church_as users(:three), churches(:grace)

    get member_path(users(:three))

    assert_response :success
    assert_select "h1", users(:three).name
  end

  test "volunteer cannot list all members" do
    sign_in_to_church_as users(:three), churches(:grace)

    get members_path

    assert_redirected_to root_path
  end

  test "volunteer cannot see another member profile" do
    sign_in_to_church_as users(:three), churches(:grace)

    get member_path(users(:one))

    assert_redirected_to root_path
  end
end
