require "test_helper"

class ScheduleAssignmentPolicyTest < ActiveSupport::TestCase
  setup do
    Current.church = churches(:grace)
  end

  teardown do
    Current.reset
  end

  test "church admin can manage all assignments" do
    Current.church_membership = church_memberships(:grace_admin)
    policy = ScheduleAssignmentPolicy.new(users(:one), schedule_assignments(:pending_vocal))

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.destroy?
    assert policy.respond?
  end

  test "church admin cannot respond to another user's assignment" do
    Current.church_membership = church_memberships(:grace_admin)
    assignment = churches(:grace).schedule_assignments.create!(
      event: events(:sunday_service),
      event_requirement: event_requirements(:guitar_slot),
      user: users(:three)
    )

    policy = ScheduleAssignmentPolicy.new(users(:one), assignment)

    assert_not policy.respond?
  end

  test "scope returns department leader assignments only for departments they lead" do
    Current.church_membership = church_memberships(:grace_admin)
    church_memberships(:grace_admin).department_leader!

    led_event = Event.create!(
      church: churches(:grace),
      department: departments(:welcome),
      title: "Welcome Briefing",
      event_type: :meeting,
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 1.hour
    )
    led_requirement = churches(:grace).event_requirements.create!(
      event: led_event,
      role_name: "Recepção",
      required_quantity: 1
    )
    led_assignment = churches(:grace).schedule_assignments.create!(
      event: led_event,
      event_requirement: led_requirement,
      user: users(:three)
    )

    scope = ScheduleAssignmentPolicy::Scope.new(users(:one), ScheduleAssignment.all).resolve

    assert_includes scope, led_assignment
    assert_not_includes scope, schedule_assignments(:declined_sound)
  end

  test "volunteer cannot respond to another user's assignment" do
    Current.church_membership = church_memberships(:grace_volunteer)

    # pending_vocal belongs to users(:one), not users(:three)
    other_policy = ScheduleAssignmentPolicy.new(users(:three), schedule_assignments(:pending_vocal))

    assert_not other_policy.respond?
  end

  test "assigned volunteer can respond to their own assignment" do
    Current.church_membership = church_memberships(:grace_volunteer)

    assignment = churches(:grace).schedule_assignments.create!(
      event: events(:sunday_service),
      event_requirement: event_requirements(:guitar_slot),
      user: users(:three)
    )
    policy = ScheduleAssignmentPolicy.new(users(:three), assignment)

    assert policy.respond?
  end

  test "church admin can replace declined assignments" do
    Current.church_membership = church_memberships(:grace_admin)
    policy = ScheduleAssignmentPolicy.new(users(:one), schedule_assignments(:declined_sound))

    assert policy.declined_replacements?
    assert policy.replace?
  end

  test "department leader can replace declined assignments only in managed departments" do
    Current.church_membership = church_memberships(:grace_admin)
    church_memberships(:grace_admin).department_leader!
    policy = ScheduleAssignmentPolicy.new(users(:one), schedule_assignments(:declined_sound))

    assert policy.declined_replacements?
    assert_not policy.replace?
  end

  test "volunteer cannot access declined replacement queue" do
    Current.church_membership = church_memberships(:grace_volunteer)
    policy = ScheduleAssignmentPolicy.new(users(:three), schedule_assignments(:declined_sound))

    assert_not policy.declined_replacements?
    assert_not policy.replace?
  end
end
