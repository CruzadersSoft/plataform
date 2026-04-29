require "test_helper"

class Assignments::RespondToAssignmentTest < ActiveSupport::TestCase
  test "volunteer confirms a pending assignment" do
    assignment = schedule_assignments(:pending_vocal)

    result = Assignments::RespondToAssignment.new(
      assignment: assignment,
      actor: assignment.user,
      response: :confirmed
    ).call

    assert result.success?
    assert assignment.reload.confirmed?
    assert_not_nil assignment.response_at
  end

  test "volunteer declines a pending assignment with reason" do
    assignment = schedule_assignments(:pending_vocal)

    result = Assignments::RespondToAssignment.new(
      assignment: assignment,
      actor: assignment.user,
      response: :declined,
      decline_reason: "Compromisso familiar"
    ).call

    assert result.success?
    assert assignment.reload.declined?
    assert_not_nil assignment.response_at
    assert_equal "Compromisso familiar", assignment.decline_reason
  end

  test "decline without reason returns failure" do
    assignment = schedule_assignments(:pending_vocal)

    result = Assignments::RespondToAssignment.new(
      assignment: assignment,
      actor: assignment.user,
      response: :declined
    ).call

    assert_not result.success?
    assert assignment.reload.pending?
  end

  test "cannot respond to an already confirmed assignment" do
    assignment = schedule_assignments(:confirmed_guitar)

    result = Assignments::RespondToAssignment.new(
      assignment: assignment,
      actor: users(:one),
      response: :declined,
      decline_reason: "Mudança de planos"
    ).call

    assert_not result.success?
    assert_includes result.errors, "Designação já foi respondida."
  end

  test "cannot respond to another user's assignment" do
    assignment = schedule_assignments(:pending_vocal)

    result = Assignments::RespondToAssignment.new(
      assignment: assignment,
      actor: users(:three),
      response: :confirmed
    ).call

    assert_not result.success?
    assert_includes result.errors, "Apenas o voluntário convocado pode responder."
  end
end
