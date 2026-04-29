module Tasks
  class CreateTask
    def initialize(church:, params:, actor:)
      @church = church
      @params = params
      @actor  = actor
    end

    def call
      task = @church.tasks.new(task_params.merge(created_by: @actor.id))

      if task.save
        ApplicationServiceResult.new(success: true, task: task)
      else
        ApplicationServiceResult.new(success: false, task: task, errors: task.errors.full_messages)
      end
    end

    private

    def task_params
      @params.slice(:title, :description, :priority, :status, :department_id, :assigned_user_id, :due_at)
    end
  end
end
