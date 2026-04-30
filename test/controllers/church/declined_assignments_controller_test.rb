require "test_helper"

class Church::DeclinedAssignmentsControllerTest < ActionDispatch::IntegrationTest
  test "church admin lists unresolved declined assignments" do
    sign_in_to_church_as users(:one), churches(:grace)

    get declined_assignments_path

    assert_response :success
    assert_select "h1", "Recusas pendentes"
    assert_select "[data-testid='declined-assignment-row']", count: 1
    assert_match users(:three).display_name, response.body
  end

  test "department leader lists only managed department declined assignments" do
    church_memberships(:grace_admin).department_leader!
    welcome_assignment = create_welcome_decline

    sign_in_to_church_as users(:one), churches(:grace)
    get declined_assignments_path

    assert_response :success
    assert_select "[data-testid='declined-assignment-row']", count: 1
    assert_match welcome_assignment.event.title, response.body
    assert_no_match events(:worship_rehearsal).title, response.body
  end

  test "volunteer cannot access declined assignment queue" do
    sign_in_to_church_as users(:three), churches(:grace)

    get declined_assignments_path

    assert_redirected_to root_path
  end

  test "church admin opens replacement screen" do
    churches(:grace).church_memberships.create!(
      user: users(:two),
      church_role: :volunteer,
      status: :active
    )
    sign_in_to_church_as users(:one), churches(:grace)

    get declined_assignment_path(schedule_assignments(:declined_sound))

    assert_response :success
    assert_select "h1", "Substituir voluntário"
    assert_select "select[name='assignment[replacement_user_id]'] option", text: users(:two).display_name
    assert_select "select[name='assignment[replacement_user_id]'] option", text: users(:one).display_name, count: 0
    assert_select "select[name='assignment[leadership_user_id]'] option", text: users(:one).display_name
  end

  test "church admin replaces a declined assignment with an operational volunteer" do
    declined_assignment = schedule_assignments(:declined_sound)
    churches(:grace).church_memberships.create!(
      user: users(:two),
      church_role: :volunteer,
      status: :active
    )
    sign_in_to_church_as users(:one), churches(:grace)

    assert_difference "ScheduleAssignment.count", 1 do
      assert_difference "Notification.count", 1 do
        assert_difference "ActivityLog.count", 2 do
          patch replace_declined_assignment_path(declined_assignment), params: {
            assignment: { replacement_user_id: users(:two).id }
          }
        end
      end
    end

    assert_redirected_to declined_assignments_path
    assert declined_assignment.reload.replacement_resolved?
    assert_equal users(:two), declined_assignment.replacement_assignment.user
  end

  test "church admin explicitly replaces a decline with pastor admin" do
    declined_assignment = schedule_assignments(:declined_sound)
    sign_in_to_church_as users(:one), churches(:grace)

    assert_difference "ScheduleAssignment.count", 1 do
      patch replace_declined_assignment_path(declined_assignment), params: {
        assignment: { leadership_user_id: users(:one).id }
      }
    end

    assert_redirected_to declined_assignments_path
    assert_equal users(:one), declined_assignment.reload.replacement_assignment.user
  end

  test "replacement requires selecting a substitute" do
    declined_assignment = schedule_assignments(:declined_sound)
    sign_in_to_church_as users(:one), churches(:grace)

    assert_no_difference "ScheduleAssignment.count" do
      patch replace_declined_assignment_path(declined_assignment)
    end

    assert_response :unprocessable_entity
    assert_match "Selecione um substituto.", response.body
  end

  test "resolved decline leaves the queue" do
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

    sign_in_to_church_as users(:one), churches(:grace)
    get declined_assignments_path

    assert_response :success
    assert_select "[data-testid='declined-assignment-row']", count: 0
  end

  private

    def create_welcome_decline
      event = churches(:grace).events.create!(
        department: departments(:welcome),
        title: "Recepção especial",
        event_type: :meeting,
        starts_at: 4.days.from_now,
        ends_at: 4.days.from_now + 1.hour
      )
      requirement = churches(:grace).event_requirements.create!(
        event: event,
        role_name: "Recepção",
        required_quantity: 1
      )
      churches(:grace).schedule_assignments.create!(
        event: event,
        event_requirement: requirement,
        user: users(:three),
        status: :declined,
        response_at: Time.current,
        decline_reason: "Outro compromisso"
      )
    end
end
