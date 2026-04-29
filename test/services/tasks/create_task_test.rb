require "test_helper"

class Tasks::CreateTaskTest < ActiveSupport::TestCase
  test "creates a task with valid params" do
    params = {
      title: "Organizar cadeiras",
      description: "Preparar o salão",
      priority: "high",
      department_id: departments(:welcome).id,
      due_at: 5.days.from_now
    }

    result = Tasks::CreateTask.new(
      church: churches(:grace),
      params: params,
      actor: users(:one)
    ).call

    assert result.success?
    assert_equal "Organizar cadeiras", result.task.title
    assert_equal users(:one).id, result.task.created_by
    assert_equal churches(:grace), result.task.church
    assert result.task.pending?
  end

  test "returns failure with invalid params" do
    result = Tasks::CreateTask.new(
      church: churches(:grace),
      params: { title: "", department_id: departments(:welcome).id },
      actor: users(:one)
    ).call

    assert_not result.success?
    assert_not_empty result.errors
  end

  test "does not create task when department belongs to another church" do
    params = {
      title: "Tarefa inválida",
      department_id: departments(:hope_care).id
    }

    result = Tasks::CreateTask.new(
      church: churches(:grace),
      params: params,
      actor: users(:one)
    ).call

    assert_not result.success?
  end
end
