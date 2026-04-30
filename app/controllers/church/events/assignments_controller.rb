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
    return redirect_to event_path(@event), alert: blank_selection_message if users.empty?

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
      redirect_to event_path(@event), notice: success_message(users)
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
    return find_leadership_users if leadership_assignment?

    user_ids = Array(params.dig(:assignment, :user_ids)).reject(&:blank?)
    user_ids = [ params.dig(:assignment, :user_id) ].compact_blank if user_ids.empty?

    assignment_candidates.operational_memberships.where(user_id: user_ids).map(&:user)
  end

  def find_leadership_users
    user_id = params.dig(:assignment, :leadership_user_id)
    return User.none if user_id.blank?

    assignment_candidates.leadership_memberships.where(user_id: user_id).map(&:user)
  end

  def assignment_candidates
    ::Assignments::CandidatesQuery.new(church: Current.church, event: @event, actor: Current.user)
  end

  def leadership_assignment?
    params.dig(:assignment, :leadership_user_id).present?
  end

  def blank_selection_message
    return "Selecione um pastor/admin disponível para convocar." if leadership_assignment?

    "Selecione pelo menos um voluntário para convocar."
  end

  def success_message(users)
    return "Pastor/admin convocado com sucesso." if leadership_assignment?

    users.many? ? "Voluntários convocados com sucesso." : "Voluntário convocado com sucesso."
  end
end
