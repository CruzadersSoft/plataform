require "test_helper"

class Church::EventsControllerTest < ActionDispatch::IntegrationTest
  test "church admin lists events for the active church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get events_path

    assert_response :success
    assert_select "h1", "Eventos"
    assert_select "[data-testid='event-row']", count: 2
  end

  test "does not list events from another church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get events_path

    assert_select "[data-testid='event-row']" do |rows|
      rows.each do |row|
        assert_no_match events(:hope_meeting).title, row.to_s
      end
    end
  end

  test "church admin renders new event form with department options" do
    sign_in_to_church_as users(:one), churches(:grace)

    get new_event_path

    assert_response :success
    assert_select "h1", "Novo Evento"
    assert_select "form"
    assert_select "select[name='event[department_id]']"
    assert_select "select[name='event[event_type]']"
  end

  test "church admin creates an event" do
    sign_in_to_church_as users(:one), churches(:grace)

    assert_difference "Event.count", 1 do
      post events_path, params: {
        event: {
          title: "Culto de Quarta",
          event_type: "service",
          starts_at: 3.days.from_now.beginning_of_day + 19.hours,
          ends_at: 3.days.from_now.beginning_of_day + 21.hours,
          location: "Sede"
        }
      }
    end

    event = Event.order(:created_at).last
    assert_redirected_to event_path(event)
    assert_equal churches(:grace), event.church
    assert event.draft?
  end

  test "event show renders volunteer invitation form" do
    sign_in_to_church_as users(:one), churches(:grace)

    get event_path(events(:sunday_service))

    assert_response :success
    assert_select "h2", "Convocações"
    assert_select "h2", { text: "Vagas", count: 0 }
    assert_select "select[name='assignment[user_ids][]']"
    assert_select "input[name='assignment[decline_reason]']", count: 0
    assert_select "form[action='#{confirm_assignment_path(schedule_assignments(:pending_vocal))}']", count: 0
  end

  test "event invitation form shows email when volunteer has no name" do
    users(:three).update!(name: nil)
    sign_in_to_church_as users(:one), churches(:grace)

    get event_path(events(:sunday_service))

    assert_response :success
    assert_select "select[name='assignment[user_ids][]'] option", text: users(:three).email_address
  end

  test "event invitation form does not list volunteers unavailable during the event" do
    event = events(:sunday_service)
    churches(:grace).unavailabilities.create!(
      user: users(:three),
      starts_at: event.starts_at - 1.hour,
      ends_at: event.ends_at + 1.hour,
      status: :active
    )
    sign_in_to_church_as users(:one), churches(:grace)

    get event_path(event)

    assert_response :success
    assert_select "select[name='assignment[user_ids][]'] option", text: users(:three).display_name, count: 0
  end

  test "event invitation form does not list volunteers already convocated to the event" do
    event = events(:sunday_service)
    churches(:grace).schedule_assignments.create!(
      event: event,
      event_requirement: event_requirements(:guitar_slot),
      user: users(:three)
    )
    sign_in_to_church_as users(:one), churches(:grace)

    get event_path(event)

    assert_response :success
    assert_select "select[name='assignment[user_ids][]'] option", text: users(:three).display_name, count: 0
  end

  test "event invitation form does not list volunteers assigned to overlapping events" do
    event = events(:sunday_service)
    overlapping_event = churches(:grace).events.create!(
      department: departments(:welcome),
      title: "Recepção especial",
      event_type: :meeting,
      starts_at: event.starts_at + 30.minutes,
      ends_at: event.ends_at + 30.minutes
    )
    requirement = churches(:grace).event_requirements.create!(
      event: overlapping_event,
      role_name: "Recepção",
      required_quantity: 1
    )
    churches(:grace).schedule_assignments.create!(
      event: overlapping_event,
      event_requirement: requirement,
      user: users(:three)
    )
    sign_in_to_church_as users(:one), churches(:grace)

    get event_path(event)

    assert_response :success
    assert_select "select[name='assignment[user_ids][]'] option", text: users(:three).display_name, count: 0
  end

  test "event invitation form still lists volunteers with non-overlapping unavailability" do
    event = events(:sunday_service)
    churches(:grace).unavailabilities.create!(
      user: users(:three),
      starts_at: event.ends_at + 1.hour,
      ends_at: event.ends_at + 2.hours,
      status: :active
    )
    sign_in_to_church_as users(:one), churches(:grace)

    get event_path(event)

    assert_response :success
    assert_select "select[name='assignment[user_ids][]'] option", text: users(:three).display_name
  end

  test "church admin publishes an event" do
    sign_in_to_church_as users(:one), churches(:grace)

    patch publish_event_path(events(:worship_rehearsal))

    assert_redirected_to event_path(events(:worship_rehearsal))
    assert events(:worship_rehearsal).reload.published?
  end

  test "volunteer cannot create an event" do
    sign_in_to_church_as users(:three), churches(:grace)

    post events_path, params: {
      event: {
        title: "Evento Voluntário",
        event_type: "service",
        starts_at: 1.week.from_now,
        ends_at: 1.week.from_now + 2.hours
      }
    }

    assert_redirected_to root_path
  end

  test "cannot access event from another church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get event_path(events(:hope_meeting))

    assert_response :not_found
  end
end
