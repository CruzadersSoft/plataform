module Platform
  class ChurchesController < ApplicationController
    skip_before_action :require_current_church

    before_action :set_church, only: %i[show edit update]

    def index
      authorize Church, policy_class: Platform::ChurchPolicy
      @churches = policy_scope(Church, policy_scope_class: Platform::ChurchPolicy::Scope).order(:name)
    end

    def show
      authorize @church, policy_class: Platform::ChurchPolicy
    end

    def new
      @church = Church.new(timezone: "America/Sao_Paulo")
      authorize @church, policy_class: Platform::ChurchPolicy
    end

    def create
      @church = Church.new(church_params)
      authorize @church, policy_class: Platform::ChurchPolicy

      if @church.save
        redirect_to platform_church_path(@church), notice: "Igreja criada com sucesso."
      else
        flash.now[:alert] = "Nao foi possivel criar a igreja."
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @church, policy_class: Platform::ChurchPolicy
    end

    def update
      authorize @church, policy_class: Platform::ChurchPolicy

      if @church.update(church_params)
        redirect_to platform_church_path(@church), notice: "Igreja atualizada com sucesso."
      else
        flash.now[:alert] = "Nao foi possivel atualizar a igreja."
        render :edit, status: :unprocessable_entity
      end
    end

    private
      def set_church
        @church = Church.find(params[:id])
      end

      def church_params
        params.require(:church).permit(:name, :slug, :legal_name, :email, :phone, :timezone, :status)
      end
  end
end
