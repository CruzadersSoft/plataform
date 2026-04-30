class Church::EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy]

  def index
    authorize Event
    @events = policy_scope(Event).order(starts_at: :asc)
  end

  def show
    authorize @event
    @assignments = @event.schedule_assignments.includes(:user, :event_requirement)
    @available_memberships = assignment_candidates.operational_memberships
    @leadership_memberships = assignment_candidates.leadership_memberships
  end

  def new
    @event = Current.church.events.new
    authorize Event
    set_department_options
  end

  def create
    @event = Current.church.events.new(event_params)
    authorize @event

    result = Events::CreateEvent.new(church: Current.church, params: event_params, actor: Current.user).call

    if result.success?
      redirect_to event_path(result.event), notice: "Evento criado com sucesso."
    else
      @event = result.event
      set_department_options
      flash.now[:alert] = result.errors.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @event
    set_department_options
  end

  def update
    authorize @event

    @event.assign_attributes(event_params)
    authorize @event

    if @event.save
      redirect_to event_path(@event), notice: "Evento atualizado com sucesso."
    else
      set_department_options
      flash.now[:alert] = "Não foi possível atualizar o evento."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @event
    @event.cancelled!
    redirect_to events_path, notice: "Evento cancelado."
  end

  private

  def set_event
    @event = Current.church.events.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :event_type, :starts_at, :ends_at, :location, :department_id, :notes)
  end

  def assignment_candidates
    ::Assignments::CandidatesQuery.new(church: Current.church, event: @event, actor: Current.user)
  end

  def set_department_options
    @department_options =
      if Current.church_membership&.church_admin?
        Current.church.departments.active.order(:name)
      else
        Current.church
          .departments
          .active
          .joins(:department_memberships)
          .where(
            department_memberships: {
              user_id: Current.user.id,
              status: DepartmentMembership.statuses[:active],
              department_role: DepartmentMembership.department_roles[:leader]
            }
          )
          .order(:name)
          .distinct
      end
  end
end
