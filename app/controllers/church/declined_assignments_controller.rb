class Church::DeclinedAssignmentsController < ApplicationController
  before_action :set_assignment, only: %i[show replace]

  def index
    authorize ScheduleAssignment, :declined_replacements?
    @assignments = policy_scope(ScheduleAssignment)
      .unresolved_declines
      .includes(:user, :event_requirement, event: :department)
      .joins(:event)
      .order("events.starts_at ASC")
  end

  def show
    authorize @assignment, :replace?
    set_candidate_memberships
  end

  def replace
    authorize @assignment, :replace?
    replacement_user = find_replacement_user

    if replacement_user.blank?
      set_candidate_memberships
      flash.now[:alert] = "Selecione um substituto."
      return render :show, status: :unprocessable_entity
    end

    result = Assignments::ReplaceDeclinedVolunteer.new(
      church: Current.church,
      assignment: @assignment,
      replacement_user: replacement_user,
      actor: Current.user,
      ip_address: request.remote_ip
    ).call

    if result.success?
      redirect_to declined_assignments_path, notice: "Substituto convocado com sucesso."
    else
      set_candidate_memberships
      flash.now[:alert] = result.errors.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private

    def set_assignment
      @assignment = Current.church.schedule_assignments.unresolved_declines.find(params[:id])
    end

    def replacement_params
      params.fetch(:assignment, ActionController::Parameters.new).permit(:replacement_user_id, :leadership_user_id)
    end

    def find_replacement_user
      user_id = replacement_params[:leadership_user_id].presence || replacement_params[:replacement_user_id]
      return if user_id.blank?

      candidate_memberships.find { |membership| membership.user_id == user_id.to_i }&.user
    end

    def set_candidate_memberships
      @available_memberships = assignment_candidates.operational_memberships
      @leadership_memberships = assignment_candidates.leadership_memberships
    end

    def candidate_memberships
      assignment_candidates.operational_memberships + assignment_candidates.leadership_memberships
    end

    def assignment_candidates
      ::Assignments::CandidatesQuery.new(church: Current.church, event: @assignment.event, actor: Current.user)
    end
end
