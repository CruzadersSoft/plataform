require "test_helper"

class DepartmentPolicyTest < ActiveSupport::TestCase
  setup do
    Current.church = churches(:grace)
  end

  teardown do
    Current.reset
  end

  test "church admin manages every department in the active church" do
    Current.church_membership = church_memberships(:grace_admin)

    policy = DepartmentPolicy.new(users(:one), departments(:worship))

    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "department leader manages only departments they lead" do
    church_memberships(:grace_admin).department_leader!
    Current.church_membership = church_memberships(:grace_admin)

    led_policy = DepartmentPolicy.new(users(:one), departments(:welcome))
    other_policy = DepartmentPolicy.new(users(:one), departments(:worship))

    assert led_policy.show?
    assert led_policy.update?
    assert led_policy.destroy?
    assert_not other_policy.update?
    assert_not other_policy.destroy?
  end

  test "volunteer views only departments they participate in" do
    Current.church_membership = church_memberships(:grace_volunteer)

    participating_policy = DepartmentPolicy.new(users(:three), departments(:welcome))
    other_policy = DepartmentPolicy.new(users(:three), departments(:hope_care))

    assert participating_policy.show?
    assert_not participating_policy.create?
    assert_not participating_policy.update?
    assert_not other_policy.show?
  end
end
