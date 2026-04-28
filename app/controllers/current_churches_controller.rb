class CurrentChurchesController < ApplicationController
  skip_before_action :require_current_church

  def update
    result = Tenancy::ContextResolver.new(user: Current.user, church_id: params[:church_id]).call

    if result.success?
      activate_church!(result.church)
      redirect_to root_path, notice: "Igreja ativa atualizada."
    else
      session.delete(:church_id)
      redirect_to onboarding_path, alert: "Selecione uma igreja valida para continuar."
    end
  end
end
