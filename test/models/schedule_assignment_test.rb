require "test_helper"

class ScheduleAssignmentTest < ActiveSupport::TestCase
  test "requires church, event, event_requirement and user" do
    assignment = ScheduleAssignment.new

    assert_not assignment.valid?
    assert_includes assignment.errors[:church], "must exist"
    assert_includes assignment.errors[:event], "must exist"
    assert_includes assignment.errors[:event_requirement], "must exist"
    assert_includes assignment.errors[:user], "must exist"
  end

  test "defaults to pending status" do
    assignment = ScheduleAssignment.new(
      church: churches(:grace),
      event: events(:sunday_service),
      event_requirement: event_requirements(:guitar_slot),
      user: users(:one)
    )

    assert assignment.pending?
  end

  test "confirmed assignment has response_at set" do
    assignment = schedule_assignments(:confirmed_guitar)

    assert assignment.confirmed?
    assert_not_nil assignment.response_at
  end

  test "responded assignment requires response_at" do
    assignment = ScheduleAssignment.new(
      church: churches(:grace),
      event: events(:worship_rehearsal),
      event_requirement: event_requirements(:sound_slot),
      user: users(:one),
      status: :confirmed
    )

    assert_not assignment.valid?
    assert_includes assignment.errors[:response_at], "can't be blank"
  end

  test "declined assignment requires a decline_reason" do
    assignment = ScheduleAssignment.new(
      church: churches(:grace),
      event: events(:worship_rehearsal),
      event_requirement: event_requirements(:sound_slot),
      user: users(:three),
      status: :declined
    )

    assert_not assignment.valid?
    assert_includes assignment.errors[:decline_reason], "can't be blank"
  end

  test "does not allow duplicate assignment for same user and requirement" do
    duplicate = ScheduleAssignment.new(
      church: churches(:grace),
      event: events(:sunday_service),
      event_requirement: event_requirements(:guitar_slot),
      user: users(:one)
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "requirement must belong to the assignment event" do
    assignment = ScheduleAssignment.new(
      church: churches(:grace),
      event: events(:sunday_service),
      event_requirement: event_requirements(:sound_slot),
      user: users(:one)
    )

    assert_not assignment.valid?
    assert_includes assignment.errors[:event_requirement], "must belong to the event"
  end

  test "user must be an active church member" do
    assignment = ScheduleAssignment.new(
      church: churches(:grace),
      event: events(:worship_rehearsal),
      event_requirement: event_requirements(:sound_slot),
      user: users(:four)
    )

    assert_not assignment.valid?
    assert_includes assignment.errors[:user], "must be an active member of the church"
  end

  test "marks declined assignment as replacement resolved when linked to a replacement" do
    declined_assignment = schedule_assignments(:declined_sound)
    replacement = churches(:grace).schedule_assignments.create!(
      event: declined_assignment.event,
      event_requirement: declined_assignment.event_requirement,
      user: users(:one)
    )

    declined_assignment.update!(
      replacement_assignment: replacement,
      replacement_resolver: users(:one),
      replacement_resolved_at: Time.current
    )

    assert declined_assignment.replacement_resolved?
  end

  test "validates replacement assignment belongs to same event and requirement" do
    declined_assignment = schedule_assignments(:declined_sound)
    declined_assignment.replacement_assignment = schedule_assignments(:pending_vocal)

    assert_not declined_assignment.valid?
    assert_includes declined_assignment.errors[:replacement_assignment], "must belong to the same event"
  end
end
