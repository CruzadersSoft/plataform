require "test_helper"

class Announcements::CreateAnnouncementTest < ActiveSupport::TestCase
  test "creates a draft announcement with valid params" do
    params = {
      title: "Culto de Páscoa",
      body: "Venha celebrar a Páscoa conosco.",
      audience_type: "all_members"
    }

    result = Announcements::CreateAnnouncement.new(
      church: churches(:grace),
      params: params,
      actor: users(:one)
    ).call

    assert result.success?
    assert_equal "Culto de Páscoa", result.announcement.title
    assert_equal users(:one).id, result.announcement.created_by
    assert result.announcement.draft?
  end

  test "returns failure with invalid params" do
    result = Announcements::CreateAnnouncement.new(
      church: churches(:grace),
      params: { title: "", body: "" },
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_not_empty result.errors
  end
end
