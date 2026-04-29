class Task < ApplicationRecord
  belongs_to :church
  belongs_to :department
  belongs_to :assigned_user, class_name: "User", optional: true
  belongs_to :creator, class_name: "User", foreign_key: :created_by

  enum :priority, { low: 0, medium: 1, high: 2 }, default: :low
  enum :status, { pending: 0, in_progress: 1, done: 2, cancelled: 3 }, default: :pending

  validates :title, presence: true
  validate :department_belongs_to_church
  validate :assigned_user_is_active_church_member

  private

    def department_belongs_to_church
      return if church.blank? || department.blank?
      return if department.church_id == church_id

      errors.add(:department, "must belong to the same church")
    end

    def assigned_user_is_active_church_member
      return if church.blank? || assigned_user.blank?
      return if church.church_memberships.active.exists?(user: assigned_user)

      errors.add(:assigned_user, "must be an active member of the church")
    end
end
