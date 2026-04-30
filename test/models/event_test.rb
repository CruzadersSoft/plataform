require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "requires church, title, event_type, starts_at and ends_at" do
    event = Event.new

    assert_not event.valid?
    assert_includes event.errors[:church], "must exist"
    assert_includes event.errors[:title], "can't be blank"
    assert_includes event.errors[:event_type], "can't be blank"
    assert_includes event.errors[:starts_at], "can't be blank"
    assert_includes event.errors[:ends_at], "can't be blank"
  end

  test "ends_at must be after starts_at" do
    event = Event.new(
      church: churches(:grace),
      title: "Culto",
      event_type: :service,
      starts_at: 1.hour.from_now,
      ends_at: 30.minutes.from_now
    )

    assert_not event.valid?
    assert_includes event.errors[:ends_at], "must be after start time"
  end

  test "defaults to published status" do
    event = Event.new(church: churches(:grace), title: "Culto", event_type: :service,
                      starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)

    assert event.published?
  end

  test "can be cancelled" do
    events(:sunday_service).update!(status: :cancelled)

    assert events(:sunday_service).cancelled?
  end

  test "department is optional" do
    event = Event.new(
      church: churches(:grace),
      title: "Culto Geral",
      event_type: :service,
      starts_at: 1.hour.from_now,
      ends_at: 3.hours.from_now
    )

    assert event.valid?
  end

  test "department must belong to the same church" do
    event = Event.new(
      church: churches(:grace),
      department: departments(:hope_care),
      title: "Culto Geral",
      event_type: :service,
      starts_at: 1.hour.from_now,
      ends_at: 3.hours.from_now
    )

    assert_not event.valid?
    assert_includes event.errors[:department], "must belong to the same church"
  end

  test "does not mix events between churches" do
    grace_events = Event.where(church: churches(:grace))

    assert_not_includes grace_events, events(:hope_meeting)
  end
end
