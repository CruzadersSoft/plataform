require "test_helper"

class DepartmentMembershipTest < ActiveSupport::TestCase
  test "allows a volunteer to participate in multiple departments" do
    assert departments(:welcome).department_memberships.exists?(user: users(:three))
    assert departments(:worship).department_memberships.exists?(user: users(:three))
  end

  test "does not allow duplicate user membership in the same department" do
    duplicate = DepartmentMembership.new(
      church: churches(:grace),
      department: departments(:welcome),
      user: users(:three),
      department_role: :volunteer,
      status: :active
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "requires department to belong to the same church" do
    membership = DepartmentMembership.new(
      church: churches(:hope),
      department: departments(:welcome),
      user: users(:three),
      department_role: :volunteer,
      status: :active
    )

    assert_not membership.valid?
    assert_includes membership.errors[:department], "must belong to the same church"
  end

  test "requires user to be a member of the church" do
    membership = DepartmentMembership.new(
      church: churches(:hope),
      department: departments(:hope_care),
      user: users(:three),
      department_role: :volunteer,
      status: :active
    )

    assert_not membership.valid?
    assert_includes membership.errors[:user], "must be an active member of the church"
  end
end
