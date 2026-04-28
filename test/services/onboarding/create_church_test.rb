require "test_helper"

class Onboarding::CreateChurchTest < ActiveSupport::TestCase
  test "creates a church and makes the actor its church admin" do
    result = Onboarding::CreateChurch.new(
      actor: users(:two),
      params: { name: "City Church", slug: "city-church" }
    ).call

    assert result.success?
    assert result.church.persisted?
    assert_equal users(:two), result.membership.user
    assert result.membership.church_admin?
    assert result.membership.active?
    assert_equal result.church, result.membership.church
    assert result.invitation_code.persisted?
    assert result.invitation_code.volunteer?
    assert result.invitation_code.active?
    assert_equal users(:two), result.invitation_code.created_by
  end

  test "returns failure when church is invalid" do
    result = Onboarding::CreateChurch.new(actor: users(:two), params: { name: "", slug: "" }).call

    assert_not result.success?
    assert_nil result.membership
    assert_nil result.invitation_code
    assert result.church.errors.any?
  end
end
