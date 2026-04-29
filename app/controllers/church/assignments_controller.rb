class Church::AssignmentsController < ApplicationController
  before_action :set_assignment, only: %i[show confirm decline]

  def index
    authorize ScheduleAssignment
    @assignments = Current.church
      .schedule_assignments
      .where(user: Current.user)
      .includes(event: :department)
      .joins(:event)
      .order("events.starts_at ASC")
  end

  def show
    authorize @assignment
  end

  def confirm
    authorize @assignment, :respond?
    result = Assignments::RespondToAssignment.new(assignment: @assignment, actor: Current.user, response: :confirmed).call

    redirect_to assignment_path(@assignment), result.success? ? { notice: "Convocação confirmada." } : { alert: result.errors.to_sentence }
  end

  def decline
    authorize @assignment, :respond?
    result = Assignments::RespondToAssignment.new(
      assignment: @assignment,
      actor: Current.user,
      response: :declined,
      decline_reason: params.dig(:assignment, :decline_reason)
    ).call

    redirect_to assignment_path(@assignment), result.success? ? { notice: "Convocação recusada." } : { alert: result.errors.to_sentence }
  end

  private

  def set_assignment
    @assignment = Current.church.schedule_assignments.where(user: Current.user).find(params[:id])
  end
end
