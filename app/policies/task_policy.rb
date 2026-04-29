class TaskPolicy < ApplicationPolicy
  def index?
    Current.church.present?
  end

  def show?
    same_church? && visible?
  end

  def create?
    return church_admin? || department_leader? if record.is_a?(Class)

    same_church? && (church_admin? || manages_task_department?)
  end

  def update?
    same_church? && (church_admin? || manages_task_department? || assigned_to_user?)
  end

  def destroy?
    same_church? && (church_admin? || manages_task_department?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.church

      relation = scope.where(church: Current.church)
      return relation if Current.church_membership&.church_admin?

      relation
        .joins(:department)
        .left_outer_joins(department: :department_memberships)
        .where(
          "department_memberships.user_id = ? AND department_memberships.status = ?",
          user.id,
          DepartmentMembership.statuses[:active]
        )
        .or(relation.where(assigned_user: user))
        .distinct
    end
  end

  private

    def same_church?
      Current.church.present? && record.church_id == Current.church.id
    end

    def visible?
      church_admin? || manages_task_department? || assigned_to_user?
    end

    def manages_task_department?
      return false unless department_leader?

      record.department.department_memberships.active.leader.exists?(user: user)
    end

    def assigned_to_user?
      record.assigned_user_id == user.id
    end
end
