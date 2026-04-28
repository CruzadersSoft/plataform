class MemberPolicy < ApplicationPolicy
  def index?
    Current.church.present? && (church_admin? || department_leader?)
  end

  def show?
    same_church? && (church_admin? || department_leader? || record.user_id == user&.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.church

      scope.active.where(church: Current.church)
    end
  end

  private
    def same_church?
      Current.church.present? && record.church_id == Current.church.id
    end
end
