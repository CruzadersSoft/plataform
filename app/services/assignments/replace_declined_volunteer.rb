module Assignments
  class ReplaceDeclinedVolunteer
    def initialize(church:, assignment:, replacement_user:, actor:, ip_address: nil)
      @church           = church
      @assignment       = assignment
      @replacement_user = replacement_user
      @actor            = actor
      @ip_address       = ip_address
    end

    def call
      return failure("Convocação não pertence à igreja atual.") unless assignment_belongs_to_church?
      return failure("Apenas convocações recusadas podem ser substituídas.") unless @assignment.declined?
      return failure("Convocação recusada já foi resolvida.") if @assignment.replacement_resolved?
      return failure("Substituto deve ser membro ativo da igreja.") unless replacement_active_church_member?
      return failure("Substituto já foi convocado para este evento.") if already_assigned_to_event?
      return failure("Substituto está indisponível no período do evento.") if unavailable?

      replacement_assignment = nil

      ActiveRecord::Base.transaction do
        @assignment.lock!
        @replacement_user.lock!

        if @assignment.replacement_resolved?
          raise ReplacementError, "Convocação recusada já foi resolvida."
        end
        if requirement_full?
          raise ReplacementError, "Evento já atingiu a quantidade configurada de convocações."
        end
        if schedule_conflict?
          raise ReplacementError, "Substituto já está alocado em outro evento no mesmo período."
        end

        replacement_assignment = @church.schedule_assignments.create!(
          event: @assignment.event,
          event_requirement: @assignment.event_requirement,
          user: @replacement_user,
          assigned_by: @actor.id
        )

        @assignment.update!(
          replacement_assignment: replacement_assignment,
          replacement_resolver: @actor,
          replacement_resolved_at: Time.current
        )

        notify_replacement!(replacement_assignment)
        record_replacement_activity!(replacement_assignment)
      end

      ApplicationServiceResult.new(
        success: true,
        assignment: @assignment,
        replacement_assignment: replacement_assignment
      )
    rescue ReplacementError => e
      failure(e.message)
    rescue ActiveRecord::RecordInvalid => e
      ApplicationServiceResult.new(
        success: false,
        assignment: @assignment,
        replacement_assignment: replacement_assignment,
        errors: e.record.errors.full_messages
      )
    end

    private

      class ReplacementError < StandardError; end

      def assignment_belongs_to_church?
        @assignment.church_id == @church.id &&
          @assignment.event.church_id == @church.id &&
          @assignment.event_requirement.church_id == @church.id
      end

      def replacement_active_church_member?
        @church.church_memberships.active.exists?(user: @replacement_user)
      end

      def already_assigned_to_event?
        @church.schedule_assignments.exists?(event: @assignment.event, user: @replacement_user)
      end

      def unavailable?
        @church.unavailabilities
          .active
          .where(user: @replacement_user)
          .where("starts_at < ? AND ends_at > ?", @assignment.event.ends_at, @assignment.event.starts_at)
          .exists?
      end

      def requirement_full?
        @church.schedule_assignments
          .where(event_requirement: @assignment.event_requirement)
          .where.not(status: ScheduleAssignment.statuses[:declined])
          .count >= @assignment.event_requirement.required_quantity
      end

      def schedule_conflict?
        @church.schedule_assignments
          .where(user: @replacement_user)
          .where.not(status: ScheduleAssignment.statuses[:declined])
          .joins(:event)
          .where.not(event: @assignment.event)
          .where("events.starts_at < ? AND events.ends_at > ?", @assignment.event.ends_at, @assignment.event.starts_at)
          .exists?
      end

      def notify_replacement!(replacement_assignment)
        Notifications::SendNotification.new(
          church: @church,
          user: @replacement_user,
          type: "assignment_replacement",
          title: "Nova convocação",
          body: "Você foi convocado para #{replacement_assignment.event.title}.",
          related: replacement_assignment
        ).call
      end

      def record_replacement_activity!(replacement_assignment)
        metadata = {
          declined_assignment_id: @assignment.id,
          declined_user_id: @assignment.user_id,
          replacement_assignment_id: replacement_assignment.id,
          replacement_user_id: @replacement_user.id,
          event_id: @assignment.event_id,
          event_requirement_id: @assignment.event_requirement_id
        }

        record_activity!(
          church: @church,
          actor: @actor,
          entity: @assignment,
          action: "assignment.replaced",
          metadata: metadata,
          ip_address: @ip_address
        )

        record_activity!(
          church: @church,
          actor: @actor,
          entity: replacement_assignment,
          action: "assignment.replacement_created",
          metadata: metadata,
          ip_address: @ip_address
        )
      end

      def record_activity!(**attributes)
        result = Audit::RecordActivity.new(**attributes).call
        raise ReplacementError, result.errors.to_sentence unless result.success?
      end

      def failure(message)
        ApplicationServiceResult.new(
          success: false,
          assignment: @assignment,
          replacement_assignment: nil,
          errors: [ message ]
        )
      end
  end
end
