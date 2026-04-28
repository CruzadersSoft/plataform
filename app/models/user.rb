class User < ApplicationRecord
  has_secure_password
  has_many :church_memberships, dependent: :destroy
  has_many :churches, through: :church_memberships
  has_many :department_memberships, dependent: :destroy
  has_many :departments, through: :department_memberships
  has_many :created_church_invitation_codes, class_name: "ChurchInvitationCode", foreign_key: :created_by_id, dependent: :restrict_with_exception

  enum :platform_role, { member: 0, platform_admin: 1 }
  enum :status, { active: 0, inactive: 1 }

  validates :email_address, presence: true, uniqueness: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
