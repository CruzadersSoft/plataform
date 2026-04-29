class AnnouncementPolicy < ApplicationPolicy
  def index?
    Current.church.present?
  end

  def show?
    same_church? && (church_admin? || record.published?)
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

  def publish?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.church

      relation = scope.where(church: Current.church)
      return relation if Current.church_membership&.church_admin?

      relation.where(status: Announcement.statuses[:published])
    end
  end

  private

    def same_church?
      Current.church.present? && record.church_id == Current.church.id
    end
end
