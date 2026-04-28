class ChurchInvitationCode < ApplicationRecord
  belongs_to :church
  belongs_to :created_by, class_name: "User"

  enum :church_role, { volunteer: 0, department_leader: 1, church_admin: 2 }
  enum :status, { active: 0, inactive: 1 }

  scope :acceptable, -> { active.where("expires_at IS NULL OR expires_at > ?", Time.current) }

  normalizes :code, with: ->(code) { code.to_s.strip.upcase }

  validates :code, presence: true, uniqueness: true
  validates :church_role, presence: true

  before_validation :generate_code, if: -> { code.blank? }

  def acceptable?
    active? && (expires_at.blank? || expires_at.future?)
  end

  private
    def generate_code
      self.code = SecureRandom.alphanumeric(10).upcase
    end
end
