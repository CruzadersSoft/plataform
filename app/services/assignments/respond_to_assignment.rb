module Assignments
  class RespondToAssignment
    def initialize(assignment:, actor:, response:, decline_reason: nil)
      @assignment     = assignment
      @actor          = actor
      @response       = response.to_sym
      @decline_reason = decline_reason
    end

    def call
      return failure("Apenas o voluntário convocado pode responder.") unless @assignment.user_id == @actor.id
      return failure("Designação já foi respondida.") unless @assignment.pending?

      @assignment.assign_attributes(
        status: @response,
        response_at: Time.current,
        decline_reason: @decline_reason
      )

      if save_response
        ApplicationServiceResult.new(success: true, assignment: @assignment)
      else
        ApplicationServiceResult.new(success: false, assignment: @assignment, errors: @assignment.errors.full_messages)
      end
    end

    private

    def failure(message)
      ApplicationServiceResult.new(success: false, assignment: @assignment, errors: [ message ])
    end

    def save_response
      ActiveRecord::Base.transaction do
        @assignment.save!
        record_decline_activity! if @assignment.declined?
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def record_decline_activity!
      result = Audit::RecordActivity.new(
        church: @assignment.church,
        actor: @actor,
        entity: @assignment,
        action: "assignment.declined",
        metadata: {
          event_id: @assignment.event_id,
          event_requirement_id: @assignment.event_requirement_id,
          decline_reason: @assignment.decline_reason
        }
      ).call

      raise ActiveRecord::RecordInvalid, result.activity_log unless result.success?
    end
  end
end
