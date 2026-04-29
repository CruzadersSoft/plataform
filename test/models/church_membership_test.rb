require "test_helper"

class ChurchMembershipTest < ActiveSupport::TestCase
  test "requires one membership per user and church" do
    membership = ChurchMembership.new(
      church: churches(:grace),
      user: users(:one),
      church_role: :volunteer,
      status: :active
    )

    assert_not membership.valid?
    assert_includes membership.errors[:user_id], "has already been taken"
  end

  test "does not allow a user to have more than one active church membership" do
    membership = ChurchMembership.new(
      church: churches(:hope),
      user: users(:one),
      church_role: :church_admin,
      status: :active
    )

    assert_not membership.valid?
    assert_includes membership.errors[:user], "can only belong to one active church"
  end

  test "allows historical inactive membership for another church" do
    membership = ChurchMembership.new(
      church: churches(:hope),
      user: users(:one),
      church_role: :church_admin,
      status: :inactive
    )

    assert membership.valid?
  end

  test "church role belongs to the membership context" do
    membership = church_memberships(:grace_admin)

    assert membership.church_admin?
    assert_equal churches(:grace), membership.church
    assert_equal users(:one), membership.user
  end

  test "effective role label shows department leadership for volunteers" do
    department_memberships(:worship_volunteer).leader!

    assert_equal "Lider: Worship", church_memberships(:grace_volunteer).effective_role_label
  end

  test "effective role label keeps church admin as the primary role" do
    assert_equal "Church admin", church_memberships(:grace_admin).effective_role_label
  end

  test "pure_volunteer is false when volunteer leads a department" do
    department_memberships(:worship_volunteer).leader!

    assert_not church_memberships(:grace_volunteer).pure_volunteer?
  end

  test "pure_volunteer is true for active volunteer without department leadership" do
    assert church_memberships(:grace_volunteer).pure_volunteer?
  end
end
