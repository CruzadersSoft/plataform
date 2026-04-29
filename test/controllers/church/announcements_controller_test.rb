require "test_helper"

class Church::AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  test "church admin lists all announcements" do
    sign_in_to_church_as users(:one), churches(:grace)

    get announcements_path

    assert_response :success
    assert_select "h1", "Comunicados"
    assert_select "[data-testid='announcement-row']", count: 2
  end

  test "volunteer sees only published announcements" do
    sign_in_to_church_as users(:three), churches(:grace)

    get announcements_path

    assert_response :success
    assert_select "[data-testid='announcement-row']", count: 1
  end

  test "does not list announcements from another church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get announcements_path

    assert_select "[data-testid='announcement-row']" do |rows|
      rows.each do |row|
        assert_no_match announcements(:hope_published).title, row.to_s
      end
    end
  end

  test "filters announcements by status" do
    sign_in_to_church_as users(:one), churches(:grace)

    get announcements_path(status: :draft)

    assert_response :success
    assert_select "[data-testid='announcement-row']", count: 1
    assert_select "a", text: announcements(:grace_draft).title
    assert_select "a", text: announcements(:grace_published).title, count: 0
  end

  test "church admin creates a draft announcement" do
    sign_in_to_church_as users(:one), churches(:grace)

    assert_difference "Announcement.count", 1 do
      post announcements_path, params: {
        announcement: {
          title: "Novo Comunicado",
          body: "Corpo do comunicado de teste.",
          audience_type: "all_members"
        }
      }
    end

    announcement = Announcement.order(:created_at).last
    assert_redirected_to announcement_path(announcement)
    assert announcement.draft?
  end

  test "volunteer cannot create an announcement" do
    sign_in_to_church_as users(:three), churches(:grace)

    post announcements_path, params: {
      announcement: { title: "Comunicado", body: "Corpo.", audience_type: "all_members" }
    }

    assert_redirected_to root_path
  end

  test "church admin publishes an announcement" do
    sign_in_to_church_as users(:one), churches(:grace)

    patch publish_announcement_path(announcements(:grace_draft))

    assert_redirected_to announcement_path(announcements(:grace_draft))
    assert announcements(:grace_draft).reload.published?
  end

  test "cannot access announcement from another church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get announcement_path(announcements(:hope_published))

    assert_response :not_found
  end
end
