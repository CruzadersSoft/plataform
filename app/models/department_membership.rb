class DepartmentMembership < ApplicationRecord
  belongs_to :church
  belongs_to :department
  belongs_to :user

  enum :department_role, { volunteer: 0, leader: 1 }
  enum :status, { active: 0, inactive: 1 }

  validates :user_id, uniqueness: { scope: :department_id }
  validate :department_belongs_to_church
  validate :user_is_active_church_member

  private
    def department_belongs_to_church
      return if church.blank? || department.blank?
      return if department.church_id == church_id

      errors.add(:department, "must belong to the same church")
    end

    def user_is_active_church_member
      return if church.blank? || user.blank?
      return if church.church_memberships.active.exists?(user: user)

      errors.add(:user, "must be an active member of the church")
    end
end
