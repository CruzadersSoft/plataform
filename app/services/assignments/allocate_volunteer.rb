module Assignments
  class AllocateVolunteer
    def initialize(church:, event:, user:, actor:, requirement: nil)
      @church      = church
      @event       = event
      @requirement = requirement
      @user        = user
      @actor       = actor
    end

    def call
      return failure("Vaga não pertence ao evento.") unless requirement_belongs_to_event?
      return failure("Voluntário não é membro ativo da igreja.") unless active_church_member?
      return failure("Voluntário está indisponível no período do evento.") if unavailable?

      result = nil

      ActiveRecord::Base.transaction do
        requirement.lock!
        @user.lock!
        ensure_default_requirement_capacity!

        result =
          if already_assigned?
            failure("Voluntário já foi convocado para este evento.")
          elsif requirement_full?
            failure("Evento já atingiu a quantidade configurada de convocações.")
          elsif schedule_conflict?
            failure("Voluntário já está alocado em outro evento no mesmo período.")
          else
            assignment = @church.schedule_assignments.create!(
              event: @event,
              event_requirement: requirement,
              user: @user,
              assigned_by: @actor.id
            )

            ApplicationServiceResult.new(success: true, assignment: assignment)
          end
      end

      result
    rescue ActiveRecord::RecordInvalid => e
      ApplicationServiceResult.new(success: false, assignment: nil, errors: e.record.errors.full_messages)
    end

    private

    def already_assigned?
      @church.schedule_assignments.exists?(event: @event, user: @user)
    end

    def unavailable?
      @church.unavailabilities
             .active
             .where(user: @user)
             .where("starts_at < ? AND ends_at > ?", @event.ends_at, @event.starts_at)
             .exists?
    end

    def requirement_full?
      @church.schedule_assignments
             .where(event_requirement: requirement)
             .where.not(status: ScheduleAssignment.statuses[:declined])
             .count >= requirement.required_quantity
    end

    def schedule_conflict?
      @church.schedule_assignments
             .where(user: @user)
             .where.not(status: ScheduleAssignment.statuses[:declined])
             .joins(:event)
             .where.not(event: @event)
             .where("events.starts_at < ? AND events.ends_at > ?", @event.ends_at, @event.starts_at)
             .exists?
    end

    def requirement_belongs_to_event?
      @event.church_id == @church.id &&
        requirement.church_id == @church.id &&
        requirement.event_id == @event.id
    end

    def active_church_member?
      @church.church_memberships.active.exists?(user: @user)
    end

    def failure(message)
      ApplicationServiceResult.new(success: false, assignment: nil, errors: [ message ])
    end

    def requirement
      @requirement ||= default_invitation_requirement
    end

    def default_invitation_requirement
      @event.event_requirements.find_or_create_by!(
        church: @church,
        role_name: EventRequirement::DEFAULT_INVITATION_ROLE
      ) do |requirement|
        requirement.required_quantity = default_requirement_quantity
        requirement.priority = 1
        requirement.notes = "Requisito tecnico usado para convocacoes diretas do evento."
      end
    end

    def ensure_default_requirement_capacity!
      return unless requirement.role_name == EventRequirement::DEFAULT_INVITATION_ROLE

      minimum_quantity = [ default_requirement_quantity, requirement.schedule_assignments.where.not(status: :declined).count + 1 ].max
      requirement.update!(required_quantity: minimum_quantity) if requirement.required_quantity < minimum_quantity
    end

    def default_requirement_quantity
      [ @church.church_memberships.active.count, 1 ].max
    end
  end
end
