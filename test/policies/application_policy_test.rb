require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  test "platform admin is detected from the global user role" do
    policy = ApplicationPolicy.new(users(:platform_admin), nil)

    assert policy.platform_admin?
  end

  test "church admin is detected from the active membership" do
    Current.church_membership = church_memberships(:grace_admin)

    policy = ApplicationPolicy.new(users(:one), churches(:grace))

    assert policy.church_admin?
  ensure
    Current.reset
  end

  test "department leader is detected from department membership leadership" do
    department_memberships(:worship_volunteer).leader!
    Current.church = churches(:grace)
    Current.church_membership = church_memberships(:grace_volunteer)

    policy = ApplicationPolicy.new(users(:three), departments(:worship))

    assert policy.department_leader?
  ensure
    Current.reset
  end
end
