class Church::DepartmentsController < ApplicationController
  before_action :set_department, only: %i[show edit update destroy]

  def index
    authorize Department
    @departments = policy_scope(Department).order(:name)
  end

  def show
    authorize @department
    @department_memberships = @department.department_memberships.active.includes(:user).order("users.name")
    @available_memberships = Current.church.church_memberships.active.includes(:user).order("users.name")
  end

  def new
    @department = Current.church.departments.new
    authorize @department
  end

  def create
    @department = Current.church.departments.new(department_params)
    authorize @department

    if @department.save
      redirect_to department_path(@department), notice: "Departamento criado com sucesso."
    else
      flash.now[:alert] = "Nao foi possivel criar o departamento."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @department
  end

  def update
    authorize @department

    if @department.update(department_params)
      redirect_to department_path(@department), notice: "Departamento atualizado com sucesso."
    else
      flash.now[:alert] = "Nao foi possivel atualizar o departamento."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @department
    @department.update!(active: false)
    redirect_to departments_path, notice: "Departamento inativado com sucesso."
  end

  private
    def set_department
      @department = Current.church.departments.find(params[:id])
    end

    def department_params
      params.require(:department).permit(:name, :description, :color, :active)
    end
end
