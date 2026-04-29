require "test_helper"

class UnavailabilityPolicyTest < ActiveSupport::TestCase
  setup do
    Current.church = churches(:grace)
  end

  teardown do
    Current.reset
  end

  test "church admin can manage all unavailabilities" do
    Current.church_membership = church_memberships(:grace_admin)
    policy = UnavailabilityPolicy.new(users(:one), unavailabilities(:user_one_vacation))

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "volunteer can create and view but only update their own unavailability" do
    Current.church_membership = church_memberships(:grace_volunteer)
    own_policy   = UnavailabilityPolicy.new(users(:three), unavailabilities(:user_three_travel))
    other_policy = UnavailabilityPolicy.new(users(:three), unavailabilities(:user_one_vacation))

    assert own_policy.index?
    assert own_policy.create?
    assert own_policy.update?
    assert own_policy.destroy?
    assert_not other_policy.update?
    assert_not other_policy.destroy?
  end

  test "scope for volunteer returns only their own church unavailabilities" do
    Current.church_membership = church_memberships(:grace_volunteer)
    scope = UnavailabilityPolicy::Scope.new(users(:three), Unavailability.all).resolve

    assert_includes scope, unavailabilities(:user_three_travel)
    assert_not_includes scope, unavailabilities(:user_one_vacation)
  end
end
