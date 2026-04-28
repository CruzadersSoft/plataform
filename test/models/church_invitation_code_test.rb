require "test_helper"

class ChurchInvitationCodeTest < ActiveSupport::TestCase
  test "generates a code when none is provided" do
    invitation = ChurchInvitationCode.create!(
      church: churches(:grace),
      created_by: users(:one),
      church_role: :volunteer
    )

    assert invitation.code.present?
    assert invitation.active?
  end

  test "normalizes code" do
    invitation = ChurchInvitationCode.new(
      church: churches(:grace),
      created_by: users(:one),
      code: " abc-123 ",
      church_role: :volunteer
    )

    assert invitation.valid?
    assert_equal "ABC-123", invitation.code
  end

  test "expired invitations are not acceptable" do
    assert_not church_invitation_codes(:expired).acceptable?
  end

  test "acceptable scope excludes expired invitations" do
    assert_includes ChurchInvitationCode.acceptable, church_invitation_codes(:grace_volunteer)
    assert_not_includes ChurchInvitationCode.acceptable, church_invitation_codes(:expired)
  end
end
