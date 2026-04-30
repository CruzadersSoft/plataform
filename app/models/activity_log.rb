class ActivityLog < ApplicationRecord
  belongs_to :church
  belongs_to :actor_user, class_name: "User"

  validates :entity_type, presence: true
  validates :entity_id, presence: true
  validates :action, presence: true
  validate :actor_is_active_church_member_or_platform_admin

  private

    def actor_is_active_church_member_or_platform_admin
      return if church.blank? || actor_user.blank?
      return if actor_user.platform_admin?
      return if church.church_memberships.active.exists?(user: actor_user)

      errors.add(:actor_user, "must be an active member of the church")
    end
end
