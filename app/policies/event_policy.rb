class EventPolicy < ApplicationPolicy
  def index?
    Current.church.present?
  end

  def show?
    return false unless same_church?
    return true if church_admin?
    return manages_event_department? if department_leader?

    participates_in_event_department?
  end

  def create?
    return church_admin? || department_leader? if record.is_a?(Class)

    same_church? && (church_admin? || manages_event_department?)
  end

  def update?
    same_church? && (church_admin? || manages_event_department?)
  end

  def destroy?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.church

      relation = scope.where(church: Current.church)
      return relation if Current.church_membership&.church_admin?

      if department_leader?
        return relation
          .joins(department: :department_memberships)
          .where(
            department_memberships: {
              user_id: user.id,
              status: DepartmentMembership.statuses[:active],
              department_role: DepartmentMembership.department_roles[:leader]
            }
          )
          .distinct
      end

      relation
        .left_outer_joins(department: :department_memberships)
        .where(
          "events.department_id IS NULL OR (department_memberships.user_id = ? AND department_memberships.status = ?)",
          user.id,
          DepartmentMembership.statuses[:active]
        )
        .distinct
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

    def manages_event_department?
      return false unless department_leader?
      return false if record.department_id.blank?

      record.department.department_memberships.active.leader.exists?(user: user)
    end

    def participates_in_event_department?
      return true if record.department_id.blank?

      record.department.department_memberships.active.exists?(user: user)
    end
end
