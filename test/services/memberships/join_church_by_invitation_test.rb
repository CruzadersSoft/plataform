require "test_helper"

class Memberships::JoinChurchByInvitationTest < ActiveSupport::TestCase
  test "creates an active membership from an invitation code" do
    invitation = church_invitation_codes(:grace_volunteer)

    result = Memberships::JoinChurchByInvitation.new(actor: users(:two), code: invitation.code).call

    assert result.success?
    assert_equal churches(:grace), result.church
    assert_equal users(:two), result.membership.user
    assert result.membership.volunteer?
    assert result.membership.active?
  end

  test "rejects an expired invitation code" do
    result = Memberships::JoinChurchByInvitation.new(actor: users(:two), code: church_invitation_codes(:expired).code).call

    assert_not result.success?
    assert_nil result.membership
  end

  test "does not duplicate an existing membership" do
    result = Memberships::JoinChurchByInvitation.new(actor: users(:one), code: church_invitation_codes(:grace_volunteer).code).call

    assert_not result.success?
    assert_equal church_memberships(:grace_admin), result.membership
  end

  test "does not join another church when actor already has an active church" do
    invitation = churches(:hope).church_invitation_codes.create!(
      created_by: users(:one),
      church_role: :volunteer,
      status: :active
    )

    result = Memberships::JoinChurchByInvitation.new(actor: users(:one), code: invitation.code).call

    assert_not result.success?
    assert_nil result.church
    assert_includes result.errors, "Usuario ja possui uma igreja ativa."
  end
end
