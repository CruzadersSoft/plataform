class ScheduleAssignmentPolicy < ApplicationPolicy
  def index?
    Current.church.present?
  end

  def show?
    same_church? && (church_admin? || own_assignment?)
  end

  def create?
    church_admin? || department_leader?
  end

  def destroy?
    same_church? && (church_admin? || event_policy.update?)
  end

  def respond?
    same_church? && own_assignment?
  end

  def declined_replacements?
    church_admin? || department_leader?
  end

  def replace?
    same_church? &&
      record.declined? &&
      !record.replacement_resolved? &&
      (church_admin? || event_policy.update?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.church

      relation = scope.where(church: Current.church)
      return relation if Current.church_membership&.church_admin?

      if department_leader?
        return relation
          .left_outer_joins(event: { department: :department_memberships })
          .where(
            "events.department_id IS NULL OR (department_memberships.user_id = ? AND department_memberships.status = ? AND department_memberships.department_role = ?)",
            user.id,
            DepartmentMembership.statuses[:active],
            DepartmentMembership.department_roles[:leader]
          )
          .distinct
      end

      relation.where(user: user)
    end

    private

    def department_leader?
      return false unless Current.church.present? && Current.church_membership&.active?
      return true if Current.church_membership.department_leader?

      user.department_memberships.active.leader.exists?(church: Current.church)
    end
  end

  private

  def same_church?
    Current.church.present? && record.church_id == Current.church.id
  end

  def own_assignment?
    record.user_id == user.id
  end

  def event_policy
    EventPolicy.new(user, record.event)
  end
end
