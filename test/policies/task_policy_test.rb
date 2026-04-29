require "test_helper"

class TaskPolicyTest < ActiveSupport::TestCase
  setup do
    Current.church = churches(:grace)
  end

  teardown do
    Current.reset
  end

  test "church admin can manage tasks" do
    Current.church_membership = church_memberships(:grace_admin)
    policy = TaskPolicy.new(users(:one), tasks(:grace_pending))

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "department leader can manage tasks from their department" do
    Current.church_membership = church_memberships(:grace_admin)
    church_memberships(:grace_admin).department_leader!

    policy = TaskPolicy.new(users(:one), tasks(:grace_pending))

    assert policy.index?
    assert policy.show?
    assert policy.update?
    assert policy.destroy?
  end

  test "volunteer cannot create or manage tasks" do
    Current.church_membership = church_memberships(:grace_volunteer)
    policy = TaskPolicy.new(users(:three), tasks(:grace_pending))

    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "assigned volunteer can update their own task" do
    Current.church_membership = church_memberships(:grace_volunteer)
    task = tasks(:grace_pending)
    task.update!(assigned_user: users(:three))

    policy = TaskPolicy.new(users(:three), task)

    assert policy.update?
  end

  test "cannot access task from another church" do
    Current.church_membership = church_memberships(:grace_admin)
    policy = TaskPolicy.new(users(:one), tasks(:hope_task))

    assert_not policy.show?
    assert_not policy.update?
  end

  test "scope returns only tasks from current church" do
    Current.church_membership = church_memberships(:grace_admin)
    scope = TaskPolicy::Scope.new(users(:one), Task.all).resolve

    assert_includes scope, tasks(:grace_pending)
    assert_not_includes scope, tasks(:hope_task)
  end
end
