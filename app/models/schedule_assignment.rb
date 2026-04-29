class ScheduleAssignment < ApplicationRecord
  belongs_to :church
  belongs_to :event
  belongs_to :event_requirement
  belongs_to :user
  belongs_to :assigner, class_name: "User", foreign_key: :assigned_by, optional: true

  enum :status, { pending: 0, confirmed: 1, declined: 2 }, default: :pending

  validates :decline_reason, presence: true, if: :declined?
  validates :response_at, presence: true, if: :responded?
  validates :user_id, uniqueness: { scope: :event_requirement_id }
  validate :event_belongs_to_church
  validate :requirement_belongs_to_event_and_church
  validate :user_is_active_church_member

  private

  def responded?
    confirmed? || declined?
  end

  def event_belongs_to_church
    return if church.blank? || event.blank?
    return if event.church_id == church_id

    errors.add(:event, "must belong to the same church")
  end

  def requirement_belongs_to_event_and_church
    return if church.blank? || event_requirement.blank?

    errors.add(:event_requirement, "must belong to the same church") if event_requirement.church_id != church_id
    return if event.blank? || event_requirement.event_id == event_id

    errors.add(:event_requirement, "must belong to the event")
  end

  def user_is_active_church_member
    return if church.blank? || user.blank?
    return if church.church_memberships.active.exists?(user: user)

    errors.add(:user, "must be an active member of the church")
  end
end
