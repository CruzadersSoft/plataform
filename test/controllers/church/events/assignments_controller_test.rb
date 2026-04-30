require "test_helper"

class Church::Events::AssignmentsControllerTest < ActionDispatch::IntegrationTest
  test "church admin creates an operational assignment for an event" do
    sign_in_to_church_as users(:one), churches(:grace)
    event = churches(:grace).events.create!(
      title: "Mutirão",
      event_type: :other,
      starts_at: 5.days.from_now,
      ends_at: 5.days.from_now + 2.hours
    )
    requirement = churches(:grace).event_requirements.create!(
      event: event,
      role_name: "Apoio",
      required_quantity: 1
    )

    assert_difference "ScheduleAssignment.count", 1 do
      post event_assignments_path(event), params: {
        assignment: {
          event_requirement_id: requirement.id,
          user_id: users(:three).id
        }
      }
    end

    assert_redirected_to event_path(event)
  end

  test "church admin convocates only operational volunteers through the default form" do
    sign_in_to_church_as users(:one), churches(:grace)
    event = churches(:grace).events.create!(
      title: "Mutirão",
      event_type: :other,
      starts_at: 5.days.from_now,
      ends_at: 5.days.from_now + 2.hours
    )

    assert_difference "ScheduleAssignment.count", 1 do
      post event_assignments_path(event), params: {
        assignment: { user_ids: [ users(:one).id, users(:three).id ] }
      }
    end

    assert_redirected_to event_path(event)
    assert_equal users(:three), ScheduleAssignment.order(:created_at).last.user
    assert_equal [ EventRequirement::DEFAULT_INVITATION_ROLE ], event.event_requirements.pluck(:role_name).uniq
  end

  test "church admin explicitly convocates a pastor admin" do
    sign_in_to_church_as users(:one), churches(:grace)
    event = churches(:grace).events.create!(
      title: "Culto pastoral",
      event_type: :service,
      starts_at: 5.days.from_now,
      ends_at: 5.days.from_now + 2.hours
    )

    assert_difference "ScheduleAssignment.count", 1 do
      post event_assignments_path(event), params: {
        assignment: { leadership_user_id: users(:one).id }
      }
    end

    assert_redirected_to event_path(event)
    assert_equal users(:one), ScheduleAssignment.order(:created_at).last.user
  end

  test "church admin cannot convocate pastor admin through the default form" do
    sign_in_to_church_as users(:one), churches(:grace)
    event = churches(:grace).events.create!(
      title: "Culto pastoral",
      event_type: :service,
      starts_at: 5.days.from_now,
      ends_at: 5.days.from_now + 2.hours
    )

    assert_no_difference "ScheduleAssignment.count" do
      post event_assignments_path(event), params: {
        assignment: { user_ids: [ users(:one).id ] }
      }
    end

    assert_redirected_to event_path(event)
  end

  test "volunteer confirms their own assignment" do
    sign_in_to_church_as users(:three), churches(:grace)
    assignment = churches(:grace).schedule_assignments.create!(
      event: events(:sunday_service),
      event_requirement: event_requirements(:guitar_slot),
      user: users(:three)
    )

    patch confirm_assignment_path(assignment)

    assert_redirected_to assignment_path(assignment)
    assert assignment.reload.confirmed?
  end

  test "volunteer declines their own assignment with reason" do
    sign_in_to_church_as users(:three), churches(:grace)
    assignment = churches(:grace).schedule_assignments.create!(
      event: events(:sunday_service),
      event_requirement: event_requirements(:guitar_slot),
      user: users(:three)
    )

    patch decline_assignment_path(assignment), params: {
      assignment: { decline_reason: "Compromisso familiar" }
    }

    assert_redirected_to assignment_path(assignment)
    assert assignment.reload.declined?
  end
end
