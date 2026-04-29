require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "requires church, department, title and created_by" do
    task = Task.new

    assert_not task.valid?
    assert_includes task.errors[:church], "must exist"
    assert_includes task.errors[:department], "must exist"
    assert_includes task.errors[:title], "can't be blank"
  end

  test "defaults to pending status and low priority" do
    task = Task.new(
      church: churches(:grace),
      department: departments(:welcome),
      title: "Nova tarefa",
      created_by: users(:one).id
    )

    assert task.pending?
    assert task.low?
  end

  test "can be marked done" do
    tasks(:grace_pending).update!(status: :done)

    assert tasks(:grace_pending).done?
  end

  test "can be cancelled via soft delete" do
    tasks(:grace_pending).update!(status: :cancelled)

    assert tasks(:grace_pending).cancelled?
  end

  test "department must belong to the same church" do
    task = Task.new(
      church: churches(:grace),
      department: departments(:hope_care),
      title: "Tarefa errada",
      created_by: users(:one).id
    )

    assert_not task.valid?
    assert_includes task.errors[:department], "must belong to the same church"
  end

  test "assigned_user is optional" do
    task = Task.new(
      church: churches(:grace),
      department: departments(:welcome),
      title: "Tarefa sem atribuição",
      created_by: users(:one).id
    )

    assert task.valid?
  end

  test "assigned_user must be an active member of the task church" do
    task = Task.new(
      church: churches(:grace),
      department: departments(:welcome),
      assigned_user: users(:four),
      title: "Tarefa com pessoa de fora",
      created_by: users(:one).id
    )

    assert_not task.valid?
    assert_includes task.errors[:assigned_user], "must be an active member of the church"
  end

  test "does not mix tasks between churches" do
    grace_tasks = Task.where(church: churches(:grace))

    assert_not_includes grace_tasks, tasks(:hope_task)
  end
end
