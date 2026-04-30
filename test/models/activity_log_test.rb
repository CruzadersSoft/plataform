require "test_helper"

class ActivityLogTest < ActiveSupport::TestCase
  test "requires actor to belong to the church unless platform admin" do
    log = churches(:grace).activity_logs.new(
      actor_user: users(:four),
      entity_type: "ScheduleAssignment",
      entity_id: schedule_assignments(:declined_sound).id,
      action: "assignment.replaced"
    )

    assert_not log.valid?
    assert_includes log.errors[:actor_user], "must be an active member of the church"
  end

  test "accepts a platform admin actor" do
    log = churches(:grace).activity_logs.new(
      actor_user: users(:platform_admin),
      entity_type: "ScheduleAssignment",
      entity_id: schedule_assignments(:declined_sound).id,
      action: "assignment.replaced"
    )

    assert log.valid?
  end
end
