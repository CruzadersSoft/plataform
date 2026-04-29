require "test_helper"

class Assignments::AllocateVolunteerTest < ActiveSupport::TestCase
  test "creates a pending assignment" do
    result = Assignments::AllocateVolunteer.new(
      church: churches(:grace),
      event: events(:worship_rehearsal),
      requirement: event_requirements(:sound_slot),
      user: users(:one),
      actor: users(:one)
    ).call

    assert result.success?
    assert result.assignment.pending?
    assert_equal users(:one), result.assignment.user
  end

  test "does not allocate a user already assigned to the same requirement" do
    # users(:one) is already in pending_vocal for vocal_slot
    result = Assignments::AllocateVolunteer.new(
      church: churches(:grace),
      event: events(:sunday_service),
      requirement: event_requirements(:vocal_slot),
      user: users(:one),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Voluntário já foi convocado para este evento."
  end

  test "does not allocate more volunteers than the required quantity" do
    result = Assignments::AllocateVolunteer.new(
      church: churches(:grace),
      event: events(:sunday_service),
      requirement: event_requirements(:vocal_slot),
      user: users(:three),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Evento já atingiu a quantidade configurada de convocações."
  end

  test "creates an internal invitation requirement when convocating directly to the event" do
    event = churches(:grace).events.create!(
      department: departments(:welcome),
      title: "Encontro de voluntários",
      event_type: :meeting,
      starts_at: 4.days.from_now,
      ends_at: 4.days.from_now + 1.hour
    )

    result = Assignments::AllocateVolunteer.new(
      church: churches(:grace),
      event: event,
      user: users(:three),
      actor: users(:one)
    ).call

    assert result.success?
    assert_equal EventRequirement::DEFAULT_INVITATION_ROLE, result.assignment.event_requirement.role_name
    assert_equal event, result.assignment.event
  end

  test "does not allocate a user to overlapping events" do
    overlapping_event = churches(:grace).events.create!(
      department: departments(:welcome),
      title: "Treinamento de recepção",
      event_type: :meeting,
      starts_at: events(:sunday_service).starts_at + 30.minutes,
      ends_at: events(:sunday_service).ends_at + 30.minutes
    )
    requirement = churches(:grace).event_requirements.create!(
      event: overlapping_event,
      role_name: "Recepção",
      required_quantity: 1
    )
    churches(:grace).schedule_assignments.create!(
      event: events(:sunday_service),
      event_requirement: event_requirements(:guitar_slot),
      user: users(:three)
    )

    result = Assignments::AllocateVolunteer.new(
      church: churches(:grace),
      event: overlapping_event,
      requirement: requirement,
      user: users(:three),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Voluntário já está alocado em outro evento no mesmo período."
  end

  test "does not allocate a requirement from another event" do
    result = Assignments::AllocateVolunteer.new(
      church: churches(:grace),
      event: events(:sunday_service),
      requirement: event_requirements(:sound_slot),
      user: users(:one),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Vaga não pertence ao evento."
  end

  test "does not allocate a user without active church membership" do
    result = Assignments::AllocateVolunteer.new(
      church: churches(:grace),
      event: events(:worship_rehearsal),
      requirement: event_requirements(:sound_slot),
      user: users(:four),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Voluntário não é membro ativo da igreja."
  end

  test "does not allocate a user with an active unavailability overlapping the event" do
    event = events(:sunday_service)
    churches(:grace).unavailabilities.create!(
      user: users(:three),
      starts_at: event.starts_at - 1.hour,
      ends_at: event.ends_at + 1.hour,
      status: :active
    )

    result = Assignments::AllocateVolunteer.new(
      church: churches(:grace),
      event: event,
      requirement: event_requirements(:guitar_slot),
      user: users(:three),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Voluntário está indisponível no período do evento."
  end
end
