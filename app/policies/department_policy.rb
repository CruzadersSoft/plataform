class DepartmentPolicy < ApplicationPolicy
  def index?
    Current.church.present?
  end

  def show?
    same_church? && (church_admin? || leads_department? || participates_in_department?)
  end

  def create?
    church_admin?
  end

  def update?
    same_church? && (church_admin? || leads_department?)
  end

  def destroy?
    update?
  end

  def manage_memberships?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.church
      return scope.where(church: Current.church) if Current.church_membership&.church_admin?

      scope
        .where(church: Current.church)
        .joins(:department_memberships)
        .where(department_memberships: { user: user, status: DepartmentMembership.statuses[:active] })
        .distinct
    end
  end

  private
    def same_church?
      Current.church.present? && record.church_id == Current.church.id
    end

    def leads_department?
      return false unless department_leader?

      record.department_memberships.active.leader.exists?(user: user)
    end

    def participates_in_department?
      record.department_memberships.active.exists?(user: user)
    end
end
