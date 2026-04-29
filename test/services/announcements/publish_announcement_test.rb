require "test_helper"

class Announcements::PublishAnnouncementTest < ActiveSupport::TestCase
  test "publishes a draft announcement" do
    assert_difference "Notification.count", 2 do
      result = Announcements::PublishAnnouncement.new(
        announcement: announcements(:grace_draft),
        actor: users(:one)
      ).call

      assert result.success?
    end

    assert announcements(:grace_draft).reload.published?
    assert_not_nil announcements(:grace_draft).published_at
  end

  test "notifies only the announcement audience" do
    result = Announcements::PublishAnnouncement.new(
      announcement: announcements(:grace_draft),
      actor: users(:one)
    ).call

    assert result.success?

    notifications = Notification.where(
      related_type: "Announcement",
      related_id: announcements(:grace_draft).id
    )

    assert_includes notifications.map(&:user), users(:one)
    assert_includes notifications.map(&:user), users(:platform_admin)
    assert_not_includes notifications.map(&:user), users(:three)
  end

  test "cannot publish an already published announcement" do
    result = Announcements::PublishAnnouncement.new(
      announcement: announcements(:grace_published),
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_not_empty result.errors
  end
end
