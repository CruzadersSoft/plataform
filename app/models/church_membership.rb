class ChurchMembership < ApplicationRecord
  belongs_to :church
  belongs_to :user
  belongs_to :inviter, class_name: "User", foreign_key: :invited_by_id, optional: true

  enum :church_role, { volunteer: 0, department_leader: 1, church_admin: 2 }
  enum :status, { active: 0, pending: 1, inactive: 2 }

  validates :user_id, uniqueness: { scope: :church_id }

  before_validation :set_joined_at, if: :active?

  private
    def set_joined_at
      self.joined_at ||= Time.current
    end
end
