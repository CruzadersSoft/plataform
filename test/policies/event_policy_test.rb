require "test_helper"

class EventPolicyTest < ActiveSupport::TestCase
  setup do
    Current.church = churches(:grace)
  end

  teardown do
    Current.reset
  end

  test "church admin can create, update and destroy events" do
    Current.church_membership = church_memberships(:grace_admin)
    policy = EventPolicy.new(users(:one), events(:sunday_service))

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "volunteer can view events but not manage them" do
    Current.church_membership = church_memberships(:grace_volunteer)
    policy = EventPolicy.new(users(:three), events(:sunday_service))

    assert policy.index?
    assert policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "department leader manages only events from departments they lead" do
    Current.church_membership = church_memberships(:grace_admin)
    church_memberships(:grace_admin).department_leader!

    led_event = EventPolicy.new(users(:one), Event.create!(
      church: churches(:grace),
      department: departments(:welcome),
      title: "Welcome Briefing",
      event_type: :meeting,
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 1.hour
    ))
    other_event = EventPolicy.new(users(:one), events(:worship_rehearsal))

    assert led_event.update?
    assert_not other_event.update?
  end

  test "department leader creates only events for departments they lead" do
    Current.church_membership = church_memberships(:grace_admin)
    church_memberships(:grace_admin).department_leader!

    led_event = Event.new(church: churches(:grace), department: departments(:welcome))
    other_event = Event.new(church: churches(:grace), department: departments(:worship))

    assert EventPolicy.new(users(:one), led_event).create?
    assert_not EventPolicy.new(users(:one), other_event).create?
  end

  test "department leader cannot create general events without a department" do
    Current.church_membership = church_memberships(:grace_admin)
    church_memberships(:grace_admin).department_leader!

    general_event = Event.new(church: churches(:grace))

    assert_not EventPolicy.new(users(:one), general_event).create?
  end

  test "cannot access event from another church" do
    Current.church_membership = church_memberships(:grace_admin)
    policy = EventPolicy.new(users(:one), events(:hope_meeting))

    assert_not policy.show?
    assert_not policy.update?
  end

  test "scope returns only events from current church" do
    Current.church_membership = church_memberships(:grace_admin)
    scope = EventPolicy::Scope.new(users(:one), Event.all).resolve

    assert_includes scope, events(:sunday_service)
    assert_not_includes scope, events(:hope_meeting)
  end
end
