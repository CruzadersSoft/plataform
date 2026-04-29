require "test_helper"

class Notifications::SendNotificationTest < ActiveSupport::TestCase
  test "creates a notification for the given user" do
    assert_difference "Notification.count", 1 do
      Notifications::SendNotification.new(
        church: churches(:grace),
        user: users(:three),
        type: "announcement",
        title: "Novo comunicado",
        body: "Um comunicado foi publicado."
      ).call
    end

    notification = Notification.order(:created_at).last
    assert_equal churches(:grace), notification.church
    assert_equal users(:three), notification.user
    assert_equal "announcement", notification.notification_type
    assert_nil notification.read_at
  end

  test "accepts an optional related record" do
    announcement = announcements(:grace_published)

    Notifications::SendNotification.new(
      church: churches(:grace),
      user: users(:three),
      type: "announcement",
      title: "Comunicado publicado",
      body: announcement.title,
      related: announcement
    ).call

    notification = Notification.order(:created_at).last
    assert_equal "Announcement", notification.related_type
    assert_equal announcement.id, notification.related_id
  end
end
