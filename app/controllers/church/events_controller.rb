class Church::EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy]

  def index
    authorize Event
    @events = policy_scope(Event).order(starts_at: :asc)
  end

  def show
    authorize @event
    @assignments = @event.schedule_assignments.includes(:user, :event_requirement)
    @available_memberships = available_memberships_for_event(@event)
  end

  def new
    @event = Current.church.events.new
    authorize Event
  end

  def create
    @event = Current.church.events.new(event_params)
    authorize @event

    result = Events::CreateEvent.new(church: Current.church, params: event_params, actor: Current.user).call

    if result.success?
      redirect_to event_path(result.event), notice: "Evento criado com sucesso."
    else
      @event = result.event
      flash.now[:alert] = result.errors.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @event
  end

  def update
    authorize @event

    if @event.update(event_params)
      redirect_to event_path(@event), notice: "Evento atualizado com sucesso."
    else
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

  def available_memberships_for_event(event)
    unavailable_user_ids = Current.church
      .unavailabilities
      .active
      .where("starts_at < ? AND ends_at > ?", event.ends_at, event.starts_at)
      .select(:user_id)

    already_convoked_user_ids = event.schedule_assignments.select(:user_id)

    conflicting_assignment_user_ids = Current.church
      .schedule_assignments
      .where.not(event: event)
      .where.not(status: ScheduleAssignment.statuses[:declined])
      .joins(:event)
      .where("events.starts_at < ? AND events.ends_at > ?", event.ends_at, event.starts_at)
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
