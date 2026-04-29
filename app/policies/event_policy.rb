class EventPolicy < ApplicationPolicy
  def index?
    Current.church.present?
  end

  def show?
    same_church? && (church_admin? || manages_event_department? || participates_in_event_department?)
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

  def publish?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.church

      relation = scope.where(church: Current.church)
      return relation if Current.church_membership&.church_admin?

      relation
        .left_outer_joins(department: :department_memberships)
        .where(
          "events.department_id IS NULL OR (department_memberships.user_id = ? AND department_memberships.status = ?)",
          user.id,
          DepartmentMembership.statuses[:active]
        )
        .distinct
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
