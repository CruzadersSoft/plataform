require "test_helper"

class Church::NotificationsControllerTest < ActionDispatch::IntegrationTest
  test "user sees their notifications sorted by unread first" do
    sign_in_to_church_as users(:three), churches(:grace)

    get notifications_path

    assert_response :success
    assert_select "h1", "Notificações"
    assert_select "[data-testid='notification-row']", count: 2
  end

  test "user filters unread notifications" do
    sign_in_to_church_as users(:three), churches(:grace)

    get notifications_path(read: :unread)

    assert_response :success
    assert_select "[data-testid='notification-row']", count: 1
    assert_select "a", text: notifications(:grace_unread).title
    assert_select "a", text: notifications(:grace_read).title, count: 0
  end

  test "user marks a notification as read on show" do
    sign_in_to_church_as users(:three), churches(:grace)

    get notification_path(notifications(:grace_unread))

    assert_response :success
    assert_not_nil notifications(:grace_unread).reload.read_at
  end

  test "cannot access notification from another church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get notification_path(notifications(:hope_notification))

    assert_response :not_found
  end

  test "cannot access another user notification within the same church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get notification_path(notifications(:grace_unread))

    assert_response :not_found
  end
end
