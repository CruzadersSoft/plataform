require "test_helper"

class Church::AssignmentsControllerTest < ActionDispatch::IntegrationTest
  test "volunteer lists only their own convocations" do
    sign_in_to_church_as users(:three), churches(:grace)

    get assignments_path

    assert_response :success
    assert_select "h1", "Minhas convocações"
    assert_select "[data-testid='assignment-row']", count: 1
    assert_select "td", text: events(:worship_rehearsal).title
    assert_no_match events(:sunday_service).title, response.body
  end

  test "pure volunteer sidebar only shows volunteer-focused sections" do
    sign_in_to_church_as users(:three), churches(:grace)

    get assignments_path

    assert_response :success
    assert_select "a[href='#{assignments_path}']", /Convocações/
    assert_select "a[href='#{unavailabilities_path}']", /Indisponível/
    assert_select ".app-sidebar a[href='#{root_path}']", count: 0
    assert_select ".app-sidebar a[href='#{departments_path}']", count: 0
    assert_select ".app-sidebar a[href='#{events_path}']", count: 0
    assert_select ".app-sidebar a[href='#{members_path}']", count: 0
  end

  test "department leader still sees operational sidebar sections" do
    department_memberships(:worship_volunteer).leader!
    sign_in_to_church_as users(:three), churches(:grace)

    get assignments_path

    assert_response :success
    assert_select ".app-sidebar a[href='#{root_path}']", /Início/
    assert_select ".app-sidebar a[href='#{departments_path}']", /Departamentos/
    assert_select ".app-sidebar a[href='#{events_path}']", /Eventos/
    assert_select ".app-sidebar a[href='#{assignments_path}']", /Convocações/
  end

  test "volunteer sees event details and response actions for pending convocation" do
    assignment = churches(:grace).schedule_assignments.create!(
      event: events(:sunday_service),
      event_requirement: event_requirements(:guitar_slot),
      user: users(:three)
    )
    sign_in_to_church_as users(:three), churches(:grace)

    get assignment_path(assignment)

    assert_response :success
    assert_select "h1", events(:sunday_service).title
    assert_select "dd", text: departments(:worship).name
    assert_select "form[action='#{confirm_assignment_path(assignment)}']"
    assert_select "form[action='#{decline_assignment_path(assignment)}']"
    assert_select "input[name='assignment[decline_reason]']"
  end

  test "volunteer cannot open another user's convocation" do
    sign_in_to_church_as users(:three), churches(:grace)

    get assignment_path(schedule_assignments(:pending_vocal))

    assert_response :not_found
  end

  test "volunteer confirms their own convocation from the dedicated screen" do
    assignment = churches(:grace).schedule_assignments.create!(
      event: events(:sunday_service),
      event_requirement: event_requirements(:guitar_slot),
      user: users(:three)
    )
    sign_in_to_church_as users(:three), churches(:grace)

    patch confirm_assignment_path(assignment)

    assert_redirected_to assignment_path(assignment)
    assert assignment.reload.confirmed?
  end

  test "volunteer declines their own convocation with reason from the dedicated screen" do
    assignment = churches(:grace).schedule_assignments.create!(
      event: events(:sunday_service),
      event_requirement: event_requirements(:guitar_slot),
      user: users(:three)
    )
    sign_in_to_church_as users(:three), churches(:grace)

    patch decline_assignment_path(assignment), params: {
      assignment: { decline_reason: "Trabalho" }
    }

    assert_redirected_to assignment_path(assignment)
    assert assignment.reload.declined?
    assert_equal "Trabalho", assignment.decline_reason
  end
end
