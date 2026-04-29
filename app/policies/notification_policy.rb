class NotificationPolicy < ApplicationPolicy
  def index?
    Current.church.present?
  end

  def show?
    same_church? && owned_by_user?
  end

  def update?
    show?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless Current.church && user

      scope.where(church: Current.church, user: user)
    end
  end

  private

    def same_church?
      Current.church.present? && record.church_id == Current.church.id
    end

    def owned_by_user?
      user.present? && record.user_id == user.id
    end
end
