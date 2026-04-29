module Announcements
  class PublishAnnouncement
    def initialize(announcement:, actor:)
      @announcement = announcement
      @actor        = actor
    end

    def call
      unless @announcement.draft?
        return ApplicationServiceResult.new(
          success: false,
          announcement: @announcement,
          errors: [ "Comunicado já foi publicado ou arquivado." ]
        )
      end

      ActiveRecord::Base.transaction do
        @announcement.update!(status: :published, published_at: Time.current)
        notify_audience!

        ApplicationServiceResult.new(success: true, announcement: @announcement)
      end
    rescue ActiveRecord::RecordInvalid => e
      ApplicationServiceResult.new(
        success: false,
        announcement: @announcement,
        errors: e.record.errors.full_messages
      )
    end

    private

      def notify_audience!
        target_users.find_each do |user|
          Notifications::SendNotification.new(
            church: @announcement.church,
            user: user,
            type: "announcement",
            title: "Novo comunicado publicado",
            body: @announcement.title,
            related: @announcement
          ).call
        end
      end

      def target_users
        User.where(id: target_user_ids)
      end

      def target_user_ids
        membership_scope = @announcement.church.church_memberships.active

        return membership_scope.select(:user_id) if @announcement.all_members?

        leader_membership_ids = membership_scope
          .where(church_role: leader_roles)
          .pluck(:user_id)

        department_leader_ids = @announcement.church
          .department_memberships
          .active
          .leader
          .pluck(:user_id)

        leader_membership_ids | department_leader_ids
      end

      def leader_roles
        [
          ChurchMembership.church_roles[:church_admin],
          ChurchMembership.church_roles[:department_leader]
        ]
      end
  end
end
