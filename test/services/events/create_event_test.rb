require "test_helper"

class Events::CreateEventTest < ActiveSupport::TestCase
  test "creates a draft event for the church" do
    params = {
      title: "Culto de Louvor",
      event_type: :service,
      starts_at: 1.week.from_now.beginning_of_day + 10.hours,
      ends_at: 1.week.from_now.beginning_of_day + 12.hours,
      location: "Sede"
    }

    result = Events::CreateEvent.new(church: churches(:grace), params: params, actor: users(:one)).call

    assert result.success?
    assert_equal churches(:grace), result.event.church
    assert result.event.draft?
    assert_equal users(:one).id, result.event.created_by
  end

  test "fails when required fields are missing" do
    result = Events::CreateEvent.new(church: churches(:grace), params: {}, actor: users(:one)).call

    assert_not result.success?
    assert_not_empty result.errors
  end

  test "does not create event if ends_at is before starts_at" do
    params = {
      title: "Culto",
      event_type: :service,
      starts_at: 2.hours.from_now,
      ends_at: 1.hour.from_now
    }

    assert_no_difference "Event.count" do
      result = Events::CreateEvent.new(church: churches(:grace), params: params, actor: users(:one)).call

      assert_not result.success?
    end
  end

  test "scopes the event to the given church" do
    params = {
      title: "Reunião Hope",
      event_type: :meeting,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours
    }

    result = Events::CreateEvent.new(church: churches(:hope), params: params, actor: users(:one)).call

    assert_equal churches(:hope), result.event.church
    assert_not_equal churches(:grace), result.event.church
  end
end
