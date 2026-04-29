require "test_helper"

class Church::Events::AssignmentsControllerTest < ActionDispatch::IntegrationTest
  test "church admin creates an assignment for an event" do
    sign_in_to_church_as users(:one), churches(:grace)

    assert_difference "ScheduleAssignment.count", 1 do
      post event_assignments_path(events(:worship_rehearsal)), params: {
        assignment: {
          event_requirement_id: event_requirements(:sound_slot).id,
          user_id: users(:one).id
        }
      }
    end

    assert_redirected_to event_path(events(:worship_rehearsal))
  end

  test "church admin convocates volunteers directly to an event" do
    sign_in_to_church_as users(:one), churches(:grace)
    event = churches(:grace).events.create!(
      title: "Mutirão",
      event_type: :other,
      starts_at: 5.days.from_now,
      ends_at: 5.days.from_now + 2.hours
    )

    assert_difference "ScheduleAssignment.count", 2 do
      post event_assignments_path(event), params: {
        assignment: { user_ids: [ users(:one).id, users(:three).id ] }
      }
    end

    assert_redirected_to event_path(event)
    assert_equal [ EventRequirement::DEFAULT_INVITATION_ROLE ], event.event_requirements.pluck(:role_name).uniq
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
