require "test_helper"

class Church::TasksControllerTest < ActionDispatch::IntegrationTest
  test "church admin lists tasks for the active church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get tasks_path

    assert_response :success
    assert_select "h1", "Tarefas"
    assert_select "[data-testid='task-row']", count: 2
  end

  test "does not list tasks from another church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get tasks_path

    assert_select "[data-testid='task-row']" do |rows|
      rows.each do |row|
        assert_no_match tasks(:hope_task).title, row.to_s
      end
    end
  end

  test "filters tasks by status" do
    sign_in_to_church_as users(:one), churches(:grace)

    get tasks_path(status: :done)

    assert_response :success
    assert_select "[data-testid='task-row']", count: 1
    assert_select "a", text: tasks(:grace_done).title
    assert_select "a", text: tasks(:grace_pending).title, count: 0
  end

  test "church admin renders new task form" do
    sign_in_to_church_as users(:one), churches(:grace)

    get new_task_path

    assert_response :success
    assert_select "h1", "Nova Tarefa"
    assert_select "form"
  end

  test "church admin creates a task" do
    sign_in_to_church_as users(:one), churches(:grace)

    assert_difference "Task.count", 1 do
      post tasks_path, params: {
        task: {
          title: "Nova tarefa de teste",
          department_id: departments(:welcome).id,
          priority: "medium",
          due_at: 3.days.from_now
        }
      }
    end

    task = Task.order(:created_at).last
    assert_redirected_to task_path(task)
    assert_equal churches(:grace), task.church
    assert_equal users(:one).id, task.created_by
    assert task.pending?
  end

  test "volunteer cannot create a task" do
    sign_in_to_church_as users(:three), churches(:grace)

    post tasks_path, params: {
      task: { title: "Tarefa voluntário", department_id: departments(:welcome).id }
    }

    assert_redirected_to root_path
  end

  test "church admin cancels a task" do
    sign_in_to_church_as users(:one), churches(:grace)

    delete task_path(tasks(:grace_pending))

    assert_redirected_to tasks_path
    assert tasks(:grace_pending).reload.cancelled?
  end

  test "cannot access task from another church" do
    sign_in_to_church_as users(:one), churches(:grace)

    get task_path(tasks(:hope_task))

    assert_response :not_found
  end
end
