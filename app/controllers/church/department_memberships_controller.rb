class Church::DepartmentMembershipsController < ApplicationController
  before_action :set_department

  def create
    authorize @department, :manage_memberships?, policy_class: DepartmentPolicy

    membership = @department.department_memberships.new(department_membership_params)
    membership.church = Current.church

    if membership.save
      redirect_to department_path(@department), notice: "Membro adicionado ao departamento."
    else
      redirect_to department_path(@department), alert: "Nao foi possivel adicionar o membro."
    end
  end

  def destroy
    authorize @department, :manage_memberships?, policy_class: DepartmentPolicy

    membership = @department.department_memberships.find(params[:id])
    membership.destroy!
    redirect_to department_path(@department), notice: "Membro removido do departamento."
  end

  private
    def set_department
      @department = Current.church.departments.find(params[:department_id])
    end

    def department_membership_params
      params.require(:department_membership).permit(:user_id, :department_role)
    end
end
