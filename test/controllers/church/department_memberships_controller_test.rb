require "test_helper"

class Church::DepartmentMembershipsControllerTest < ActionDispatch::IntegrationTest
  test "church admin adds a member to a department" do
    sign_in_to_church_as users(:one), churches(:grace)
    departments(:worship).department_memberships.find_by(user: users(:three)).destroy!

    assert_difference "DepartmentMembership.count", 1 do
      post department_memberships_path(departments(:worship)), params: {
        department_membership: {
          user_id: users(:three).id,
          department_role: "volunteer"
        }
      }
    end

    assert_redirected_to department_path(departments(:worship))
    membership = departments(:worship).department_memberships.find_by!(user: users(:three))
    assert_equal churches(:grace), membership.church
    assert membership.volunteer?
  end

  test "department leader adds a member to their department" do
    sign_in_to_church_as users(:one), churches(:grace)
    church_memberships(:grace_admin).department_leader!
    departments(:welcome).department_memberships.find_by(user: users(:three)).destroy!

    assert_difference "DepartmentMembership.count", 1 do
      post department_memberships_path(departments(:welcome)), params: {
        department_membership: {
          user_id: users(:three).id,
          department_role: "volunteer"
        }
      }
    end

    assert_redirected_to department_path(departments(:welcome))
  end

  test "department leader cannot add members to another department" do
    sign_in_to_church_as users(:one), churches(:grace)
    church_memberships(:grace_admin).department_leader!
    departments(:worship).department_memberships.find_by(user: users(:three)).destroy!

    assert_no_difference "DepartmentMembership.count" do
      post department_memberships_path(departments(:worship)), params: {
        department_membership: {
          user_id: users(:three).id,
          department_role: "volunteer"
        }
      }
    end

    assert_redirected_to root_path
  end

  test "church admin removes a department membership" do
    sign_in_to_church_as users(:one), churches(:grace)

    assert_difference "DepartmentMembership.count", -1 do
      delete department_membership_path(departments(:welcome), department_memberships(:welcome_volunteer))
    end

    assert_redirected_to department_path(departments(:welcome))
  end
end
