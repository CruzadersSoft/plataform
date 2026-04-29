class SkillPolicy < ApplicationPolicy
  def index?
    Current.church.present?
  end

  def show?
    same_church?
  end

  def create?
    church_admin?
  end

  def update?
    same_church? && church_admin?
  end

  def destroy?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.church
      scope.where(church: Current.church)
    end
  end

  private

  def same_church?
    Current.church.present? && record.church_id == Current.church.id
  end
end
