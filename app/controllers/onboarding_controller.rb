class OnboardingController < ApplicationController
  skip_before_action :require_current_church

  def show
  end

  def create
    result = if onboarding_params[:action_type] == "join_church"
      Memberships::JoinChurchByInvitation.new(actor: Current.user, code: onboarding_params[:invitation_code]).call
    else
      Onboarding::CreateChurch.new(actor: Current.user, params: church_params).call
    end

    if result.success?
      activate_church!(result.church)
      redirect_to root_path, notice: "Painel de igreja ativado."
    else
      flash.now[:alert] = "Nao foi possivel ativar o painel de igreja."
      render :show, status: :unprocessable_entity
    end
  end

  private
    def onboarding_params
      params.fetch(:onboarding, {}).permit(:action_type, :invitation_code)
    end

    def church_params
      params.fetch(:onboarding, {}).fetch(:church, {}).permit(:name, :slug, :legal_name, :email, :phone, :timezone)
    end
end
