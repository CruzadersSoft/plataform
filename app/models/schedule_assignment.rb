class ScheduleAssignment < ApplicationRecord
  belongs_to :church
  belongs_to :event
  belongs_to :event_requirement
  belongs_to :user
  belongs_to :assigner, class_name: "User", foreign_key: :assigned_by, optional: true
  belongs_to :replacement_assignment, class_name: "ScheduleAssignment", optional: true
  belongs_to :replacement_resolver, class_name: "User", foreign_key: :replacement_resolved_by, optional: true
  has_one :replaced_assignment, class_name: "ScheduleAssignment", foreign_key: :replacement_assignment_id, dependent: :nullify

  enum :status, { pending: 0, confirmed: 1, declined: 2 }, default: :pending

  validates :decline_reason, presence: true, if: :declined?
  validates :response_at, presence: true, if: :responded?
  validates :user_id, uniqueness: { scope: :event_requirement_id }
  validate :event_belongs_to_church
  validate :requirement_belongs_to_event_and_church
  validate :user_is_active_church_member
  validate :replacement_assignment_belongs_to_same_context
  validate :replacement_resolver_is_active_church_member

  scope :unresolved_declines, -> { declined.where(replacement_assignment_id: nil) }

  def replacement_resolved?
    declined? && replacement_assignment_id.present?
  end

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

  def replacement_assignment_belongs_to_same_context
    return if church.blank? || replacement_assignment.blank?

    if replacement_assignment.church_id != church_id
      errors.add(:replacement_assignment, "must belong to the same church")
    end

    if event_id.present? && replacement_assignment.event_id != event_id
      errors.add(:replacement_assignment, "must belong to the same event")
    end

    return if event_requirement_id.blank? || replacement_assignment.event_requirement_id == event_requirement_id

    errors.add(:replacement_assignment, "must belong to the same requirement")
  end

  def replacement_resolver_is_active_church_member
    return if church.blank? || replacement_resolver.blank?
    return if church.church_memberships.active.exists?(user: replacement_resolver)

    errors.add(:replacement_resolver, "must be an active member of the church")
  end
end
