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
    @available_memberships = available_memberships_for_replacement(@assignment)
  end

  def replace
    authorize @assignment, :replace?
    replacement_user = find_replacement_user

    if replacement_user.blank?
      @available_memberships = available_memberships_for_replacement(@assignment)
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
      @available_memberships = available_memberships_for_replacement(@assignment)
      flash.now[:alert] = result.errors.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private

    def set_assignment
      @assignment = Current.church.schedule_assignments.unresolved_declines.find(params[:id])
    end

    def replacement_params
      params.fetch(:assignment, ActionController::Parameters.new).permit(:replacement_user_id)
    end

    def find_replacement_user
      user_id = replacement_params[:replacement_user_id]
      return if user_id.blank?

      Current.church.users.merge(ChurchMembership.active).find_by(id: user_id)
    end

    def available_memberships_for_replacement(assignment)
      unavailable_user_ids = Current.church
        .unavailabilities
        .active
        .where("starts_at < ? AND ends_at > ?", assignment.event.ends_at, assignment.event.starts_at)
        .select(:user_id)

      already_convoked_user_ids = assignment.event.schedule_assignments.select(:user_id)

      conflicting_assignment_user_ids = Current.church
        .schedule_assignments
        .where.not(event: assignment.event)
        .where.not(status: ScheduleAssignment.statuses[:declined])
        .joins(:event)
        .where("events.starts_at < ? AND events.ends_at > ?", assignment.event.ends_at, assignment.event.starts_at)
        .select(:user_id)

      Current.church
        .church_memberships
        .active
        .where.not(user_id: unavailable_user_ids)
        .where.not(user_id: already_convoked_user_ids)
        .where.not(user_id: conflicting_assignment_user_ids)
        .joins(:user)
        .includes(:user)
        .order(Arel.sql("LOWER(COALESCE(NULLIF(users.name, ''), users.email_address))"))
    end
end
