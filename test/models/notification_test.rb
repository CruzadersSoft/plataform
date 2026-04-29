require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "requires church, user, notification_type and title" do
    notification = Notification.new

    assert_not notification.valid?
    assert_includes notification.errors[:church], "must exist"
    assert_includes notification.errors[:user], "must exist"
    assert_includes notification.errors[:notification_type], "can't be blank"
    assert_includes notification.errors[:title], "can't be blank"
  end

  test "unread scope returns only unread notifications" do
    unread = Notification.where(church: churches(:grace)).unread

    assert_includes unread, notifications(:grace_unread)
    assert_not_includes unread, notifications(:grace_read)
  end

  test "mark_read! sets read_at timestamp" do
    notification = notifications(:grace_unread)
    assert_nil notification.read_at

    notification.mark_read!

    assert_not_nil notification.reload.read_at
  end

  test "user must be an active member of the notification church" do
    notification = Notification.new(
      church: churches(:grace),
      user: users(:four),
      notification_type: "announcement",
      title: "Aviso"
    )

    assert_not notification.valid?
    assert_includes notification.errors[:user], "must be an active member of the church"
  end

  test "does not mix notifications between churches" do
    grace_notifications = Notification.where(church: churches(:grace))

    assert_not_includes grace_notifications, notifications(:hope_notification)
  end
end
