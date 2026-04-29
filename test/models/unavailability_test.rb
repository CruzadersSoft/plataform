require "test_helper"

class UnavailabilityTest < ActiveSupport::TestCase
  test "requires church, user, starts_at and ends_at" do
    unavailability = Unavailability.new

    assert_not unavailability.valid?
    assert_includes unavailability.errors[:church], "must exist"
    assert_includes unavailability.errors[:user], "must exist"
    assert_includes unavailability.errors[:starts_at], "can't be blank"
    assert_includes unavailability.errors[:ends_at], "can't be blank"
  end

  test "ends_at must be after starts_at" do
    unavailability = Unavailability.new(
      church: churches(:grace),
      user: users(:one),
      starts_at: 1.hour.from_now,
      ends_at: 30.minutes.from_now
    )

    assert_not unavailability.valid?
    assert_includes unavailability.errors[:ends_at], "must be after start time"
  end

  test "defaults to active status" do
    unavailability = Unavailability.new(
      church: churches(:grace),
      user: users(:one),
      starts_at: 1.day.from_now,
      ends_at: 2.days.from_now
    )

    assert unavailability.active?
  end

  test "scope active returns only active unavailabilities" do
    active = Unavailability.where(church: churches(:grace)).active

    assert_includes active, unavailabilities(:user_one_vacation)
    assert_not_includes active, unavailabilities(:user_one_old)
  end

  test "scope for_user returns only that user unavailabilities" do
    user_unavailabilities = Unavailability.where(church: churches(:grace), user: users(:one))

    assert_includes user_unavailabilities, unavailabilities(:user_one_vacation)
    assert_not_includes user_unavailabilities, unavailabilities(:user_two_trip)
  end
end
