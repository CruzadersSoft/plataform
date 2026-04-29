class Church::UnavailabilitiesController < ApplicationController
  before_action :set_unavailability, only: %i[edit update destroy]

  def index
    authorize Unavailability
    @unavailabilities = policy_scope(Unavailability).active.order(starts_at: :asc).includes(:user)
  end

  def new
    @unavailability = Current.church.unavailabilities.new(user: Current.user)
    authorize @unavailability
  end

  def create
    @unavailability = Current.church.unavailabilities.new(unavailability_params.merge(user: Current.user))
    authorize @unavailability

    if @unavailability.save
      redirect_to unavailabilities_path, notice: "Indisponibilidade registrada."
    else
      flash.now[:alert] = "Não foi possível registrar a indisponibilidade."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @unavailability
  end

  def update
    authorize @unavailability

    if @unavailability.update(unavailability_params)
      redirect_to unavailabilities_path, notice: "Indisponibilidade atualizada."
    else
      flash.now[:alert] = "Não foi possível atualizar a indisponibilidade."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @unavailability
    @unavailability.cancelled!
    redirect_to unavailabilities_path, notice: "Indisponibilidade cancelada."
  end

  private

  def set_unavailability
    @unavailability = Current.church.unavailabilities.find(params[:id])
  end

  def unavailability_params
    params.require(:unavailability).permit(:starts_at, :ends_at, :reason)
  end
end
