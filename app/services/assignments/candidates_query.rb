module Assignments
  class CandidatesQuery
    def initialize(church:, event:, actor: nil)
      @church = church
      @event = event
      @actor = actor
    end

    def operational_memberships
      eligible_memberships
        .where(church_role: ChurchMembership.church_roles[:volunteer])
        .where.not(user_id: @actor&.id)
    end

    def leadership_memberships
      eligible_memberships.where(church_role: ChurchMembership.church_roles[:church_admin])
    end

    private

      def eligible_memberships
        @church
          .church_memberships
          .active
          .where.not(user_id: unavailable_user_ids)
          .where.not(user_id: already_convoked_user_ids)
          .where.not(user_id: conflicting_assignment_user_ids)
          .joins(:user)
          .includes(:user)
          .order(Arel.sql("LOWER(COALESCE(NULLIF(users.name, ''), users.email_address))"))
      end

      def unavailable_user_ids
        @church
          .unavailabilities
          .active
          .where("starts_at < ? AND ends_at > ?", @event.ends_at, @event.starts_at)
          .select(:user_id)
      end

      def already_convoked_user_ids
        @event.schedule_assignments.select(:user_id)
      end

      def conflicting_assignment_user_ids
        @church
          .schedule_assignments
          .where.not(event: @event)
          .where.not(status: ScheduleAssignment.statuses[:declined])
          .joins(:event)
          .where("events.starts_at < ? AND events.ends_at > ?", @event.ends_at, @event.starts_at)
          .select(:user_id)
      end
  end
end
