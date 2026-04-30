require "test_helper"

class Assignments::ReplaceDeclinedVolunteerTest < ActiveSupport::TestCase
  test "creates a pending replacement and resolves the declined assignment" do
    declined_assignment = schedule_assignments(:declined_sound)

    assert_difference "ScheduleAssignment.count", 1 do
      assert_difference "Notification.count", 1 do
        assert_difference "ActivityLog.count", 2 do
          result = Assignments::ReplaceDeclinedVolunteer.new(
            church: churches(:grace),
            assignment: declined_assignment,
            replacement_user: users(:one),
            actor: users(:one)
          ).call

          assert result.success?
          assert result.replacement_assignment.pending?
          assert_equal users(:one), result.replacement_assignment.user
        end
      end
    end

    declined_assignment.reload
    assert declined_assignment.declined?
    assert declined_assignment.replacement_resolved?
    assert_equal users(:one), declined_assignment.replacement_resolver
    assert_equal users(:one), declined_assignment.replacement_assignment.user
    assert_not_nil declined_assignment.replacement_resolved_at
  end

  test "does not replace a pending assignment" do
    result = Assignments::ReplaceDeclinedVolunteer.new(
      church: churches(:grace),
      assignment: schedule_assignments(:pending_vocal),
      replacement_user: users(:three),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Apenas convocações recusadas podem ser substituídas."
  end

  test "does not replace an already resolved decline" do
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

    result = Assignments::ReplaceDeclinedVolunteer.new(
      church: churches(:grace),
      assignment: declined_assignment,
      replacement_user: users(:one),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Convocação recusada já foi resolvida."
  end

  test "does not replace with a user without active church membership" do
    result = Assignments::ReplaceDeclinedVolunteer.new(
      church: churches(:grace),
      assignment: schedule_assignments(:declined_sound),
      replacement_user: users(:four),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Substituto deve ser membro ativo da igreja."
  end

  test "does not replace with an unavailable user" do
    event = events(:worship_rehearsal)
    churches(:grace).unavailabilities.create!(
      user: users(:one),
      starts_at: event.starts_at - 1.hour,
      ends_at: event.ends_at + 1.hour,
      status: :active
    )

    result = Assignments::ReplaceDeclinedVolunteer.new(
      church: churches(:grace),
      assignment: schedule_assignments(:declined_sound),
      replacement_user: users(:one),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Substituto está indisponível no período do evento."
  end

  test "does not replace with a user who has a schedule conflict" do
    event = events(:worship_rehearsal)
    conflict_event = churches(:grace).events.create!(
      department: departments(:welcome),
      title: "Treinamento",
      event_type: :meeting,
      starts_at: event.starts_at + 15.minutes,
      ends_at: event.ends_at + 15.minutes
    )
    conflict_requirement = churches(:grace).event_requirements.create!(
      event: conflict_event,
      role_name: "Recepção",
      required_quantity: 1
    )
    churches(:grace).schedule_assignments.create!(
      event: conflict_event,
      event_requirement: conflict_requirement,
      user: users(:one)
    )

    result = Assignments::ReplaceDeclinedVolunteer.new(
      church: churches(:grace),
      assignment: schedule_assignments(:declined_sound),
      replacement_user: users(:one),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_includes result.errors, "Substituto já está alocado em outro evento no mesmo período."
  end
end
