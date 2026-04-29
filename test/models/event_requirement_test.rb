require "test_helper"

class EventRequirementTest < ActiveSupport::TestCase
  test "requires church, event, role_name and required_quantity" do
    req = EventRequirement.new

    assert_not req.valid?
    assert_includes req.errors[:church], "must exist"
    assert_includes req.errors[:event], "must exist"
    assert_includes req.errors[:role_name], "can't be blank"
    assert_includes req.errors[:required_quantity], "can't be blank"
  end

  test "required_quantity must be a positive integer" do
    req = EventRequirement.new(
      church: churches(:grace),
      event: events(:sunday_service),
      role_name: "Guitarra",
      required_quantity: 0
    )

    assert_not req.valid?
    assert_includes req.errors[:required_quantity], "must be greater than 0"
  end

  test "skill is optional" do
    req = EventRequirement.new(
      church: churches(:grace),
      event: events(:sunday_service),
      role_name: "Receptor",
      required_quantity: 3
    )

    assert req.valid?
  end

  test "belongs to the same church as the event" do
    req = event_requirements(:guitar_slot)

    assert_equal req.church, req.event.church
  end

  test "event must belong to the same church" do
    req = EventRequirement.new(
      church: churches(:grace),
      event: events(:hope_meeting),
      role_name: "Som",
      required_quantity: 1
    )

    assert_not req.valid?
    assert_includes req.errors[:event], "must belong to the same church"
  end

  test "skill must belong to the same church" do
    req = EventRequirement.new(
      church: churches(:grace),
      event: events(:sunday_service),
      skill: skills(:sound),
      role_name: "Som",
      required_quantity: 1
    )

    assert_not req.valid?
    assert_includes req.errors[:skill], "must belong to the same church"
  end

  test "scope for event lists only that event requirements" do
    grace_requirements = EventRequirement.where(event: events(:sunday_service))

    assert_includes grace_requirements, event_requirements(:guitar_slot)
    assert_not_includes grace_requirements, event_requirements(:sound_slot)
  end
end
