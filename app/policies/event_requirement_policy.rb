class EventRequirementPolicy < ApplicationPolicy
  def index?
    Current.church.present?
  end

  def create?
    return event_policy.update? if record.respond_to?(:event) && record.event.present?

    church_admin? || department_leader?
  end

  def update?
    same_church? && event_policy.update?
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

  def event_policy
    EventPolicy.new(user, record.respond_to?(:event) && record.event.present? ? record.event : Event.new(church: Current.church))
  end
end
