require "test_helper"

class AnnouncementTest < ActiveSupport::TestCase
  test "requires church, title, body and created_by" do
    announcement = Announcement.new

    assert_not announcement.valid?
    assert_includes announcement.errors[:church], "must exist"
    assert_includes announcement.errors[:title], "can't be blank"
    assert_includes announcement.errors[:body], "can't be blank"
  end

  test "defaults to draft status and all_members audience" do
    announcement = Announcement.new(
      church: churches(:grace),
      title: "Comunicado",
      body: "Corpo do comunicado",
      created_by: users(:one).id
    )

    assert announcement.draft?
    assert announcement.all_members?
  end

  test "can be published with a published_at timestamp" do
    announcements(:grace_draft).update!(status: :published, published_at: Time.current)

    assert announcements(:grace_draft).published?
    assert_not_nil announcements(:grace_draft).published_at
  end

  test "does not mix announcements between churches" do
    grace_announcements = Announcement.where(church: churches(:grace))

    assert_not_includes grace_announcements, announcements(:hope_published)
  end
end
