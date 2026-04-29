class Church::Events::AssignmentsController < ApplicationController
  before_action :set_event
  before_action :set_assignment, only: :destroy

  def index
    authorize ScheduleAssignment
    @assignments = policy_scope(ScheduleAssignment).where(event: @event).includes(:user, :event_requirement)
  end

  def create
    authorize @event, :update?
    users = find_users
    return redirect_to event_path(@event), alert: "Selecione pelo menos um voluntário para convocar." if users.empty?

    results = users.map do |user|
      Assignments::AllocateVolunteer.new(
        church: Current.church,
        event: @event,
        requirement: find_requirement,
        user: user,
        actor: Current.user
      ).call
    end

    failures = results.reject(&:success?)

    if failures.empty?
      redirect_to event_path(@event), notice: "Voluntários convocados com sucesso."
    else
      redirect_to event_path(@event), alert: failures.flat_map(&:errors).uniq.to_sentence
    end
  end

  def destroy
    authorize @assignment
    @assignment.destroy!
    redirect_to event_path(@event), notice: "Convocação removida."
  end

  private

  def set_event
    @event = Current.church.events.find(params[:event_id])
  end

  def set_assignment
    @assignment = @event.schedule_assignments.find(params[:id])
  end

  def find_requirement
    requirement_id = params.dig(:assignment, :event_requirement_id)
    return nil if requirement_id.blank?

    @event.event_requirements.find(requirement_id)
  end

  def find_users
    user_ids = Array(params.dig(:assignment, :user_ids)).reject(&:blank?)
    user_ids = [ params.dig(:assignment, :user_id) ].compact_blank if user_ids.empty?

    Current.church.users.merge(ChurchMembership.active).where(id: user_ids)
  end
end
