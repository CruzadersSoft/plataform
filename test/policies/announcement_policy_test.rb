require "test_helper"

class AnnouncementPolicyTest < ActiveSupport::TestCase
  setup do
    Current.church = churches(:grace)
  end

  teardown do
    Current.reset
  end

  test "church admin can manage announcements" do
    Current.church_membership = church_memberships(:grace_admin)
    policy = AnnouncementPolicy.new(users(:one), announcements(:grace_draft))

    assert policy.index?
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
    assert policy.publish?
  end

  test "volunteer can view published announcements" do
    Current.church_membership = church_memberships(:grace_volunteer)
    policy = AnnouncementPolicy.new(users(:three), announcements(:grace_published))

    assert policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.publish?
  end

  test "volunteer cannot view draft announcements" do
    Current.church_membership = church_memberships(:grace_volunteer)
    policy = AnnouncementPolicy.new(users(:three), announcements(:grace_draft))

    assert_not policy.show?
  end

  test "cannot access announcement from another church" do
    Current.church_membership = church_memberships(:grace_admin)
    policy = AnnouncementPolicy.new(users(:one), announcements(:hope_published))

    assert_not policy.show?
    assert_not policy.update?
  end

  test "scope returns published announcements for volunteers" do
    Current.church_membership = church_memberships(:grace_volunteer)
    scope = AnnouncementPolicy::Scope.new(users(:three), Announcement.all).resolve

    assert_includes scope, announcements(:grace_published)
    assert_not_includes scope, announcements(:grace_draft)
    assert_not_includes scope, announcements(:hope_published)
  end

  test "scope returns all church announcements for admins" do
    Current.church_membership = church_memberships(:grace_admin)
    scope = AnnouncementPolicy::Scope.new(users(:one), Announcement.all).resolve

    assert_includes scope, announcements(:grace_published)
    assert_includes scope, announcements(:grace_draft)
    assert_not_includes scope, announcements(:hope_published)
  end
end
