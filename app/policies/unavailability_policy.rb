class UnavailabilityPolicy < ApplicationPolicy
  def index?
    Current.church.present?
  end

  def show?
    same_church? && (church_admin? || own_record?)
  end

  def create?
    Current.church.present?
  end

  def update?
    same_church? && (church_admin? || own_record?)
  end

  def destroy?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.church
      relation = scope.where(church: Current.church)
      return relation if Current.church_membership&.church_admin?

      relation.where(user: user)
    end
  end

  private

  def same_church?
    Current.church.present? && record.church_id == Current.church.id
  end

  def own_record?
    record.user_id == user.id
  end
end
