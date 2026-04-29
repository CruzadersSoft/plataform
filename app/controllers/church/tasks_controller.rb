class Church::TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy]

  def index
    authorize Task
    @status_filter = params[:status].presence
    @tasks = policy_scope(Task).includes(:department, :assigned_user)
    @tasks = @tasks.where(status: @status_filter) if Task.statuses.key?(@status_filter)
    @tasks = @tasks.order(due_at: :asc, created_at: :desc)
  end

  def show
    authorize @task
  end

  def new
    @task = Current.church.tasks.new
    authorize Task
  end

  def create
    @task = Current.church.tasks.new(task_params)
    authorize @task

    result = Tasks::CreateTask.new(church: Current.church, params: task_params, actor: Current.user).call

    if result.success?
      redirect_to task_path(result.task), notice: "Tarefa criada com sucesso."
    else
      @task = result.task
      flash.now[:alert] = result.errors.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @task
  end

  def update
    authorize @task

    if @task.update(task_params)
      redirect_to task_path(@task), notice: "Tarefa atualizada com sucesso."
    else
      flash.now[:alert] = "Não foi possível atualizar a tarefa."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @task
    @task.cancelled!
    redirect_to tasks_path, notice: "Tarefa cancelada."
  end

  private

  def set_task
    @task = Current.church.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :priority, :status, :department_id, :assigned_user_id, :due_at)
  end
end
