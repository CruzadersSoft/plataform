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

      if @assignment.save
        ApplicationServiceResult.new(success: true, assignment: @assignment)
      else
        ApplicationServiceResult.new(success: false, assignment: @assignment, errors: @assignment.errors.full_messages)
      end
    end

    private

    def failure(message)
      ApplicationServiceResult.new(success: false, assignment: @assignment, errors: [ message ])
    end
  end
end
