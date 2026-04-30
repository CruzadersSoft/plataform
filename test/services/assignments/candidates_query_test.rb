require "test_helper"

class Assignments::CandidatesQueryTest < ActiveSupport::TestCase
  test "operational memberships exclude church admins and the actor" do
    query = Assignments::CandidatesQuery.new(
      church: churches(:grace),
      event: events(:sunday_service),
      actor: users(:three)
    )

    operational_user_ids = query.operational_memberships.map(&:user_id)

    assert_not_includes operational_user_ids, users(:one).id
    assert_not_includes operational_user_ids, users(:platform_admin).id
    assert_not_includes operational_user_ids, users(:three).id
  end

  test "leadership memberships include only available church admins" do
    query = Assignments::CandidatesQuery.new(
      church: churches(:grace),
      event: events(:sunday_service),
      actor: users(:three)
    )

    leadership_user_ids = query.leadership_memberships.map(&:user_id)

    assert_includes leadership_user_ids, users(:platform_admin).id
    assert_not_includes leadership_user_ids, users(:three).id
  end
end
