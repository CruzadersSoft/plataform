class ChurchMembership < ApplicationRecord
  belongs_to :church
  belongs_to :user
  belongs_to :inviter, class_name: "User", foreign_key: :invited_by_id, optional: true

  enum :church_role, { volunteer: 0, department_leader: 1, church_admin: 2 }
  enum :status, { active: 0, pending: 1, inactive: 2 }

  validates :user_id, uniqueness: { scope: :church_id }
  validate :only_one_active_church_per_user, if: :active?

  before_validation :set_joined_at, if: :active?

  def effective_role_label
    return church_role.humanize if church_admin?

    led_department_names = led_department_memberships.map { |membership| membership.department.name }

    return "Lider: #{led_department_names.to_sentence}" if led_department_names.any?

    church_role.humanize
  end

  def leads_department?
    led_department_memberships.exists?
  end

  def pure_volunteer?
    active? && volunteer? && !leads_department?
  end

  private
    def led_department_memberships
      user
        .department_memberships
        .active
        .leader
        .where(church: church)
        .includes(:department)
    end

    def only_one_active_church_per_user
      return if user_id.blank?

      existing_membership = user.church_memberships.active.where.not(id: id).first
      return unless existing_membership

      errors.add(:user, "can only belong to one active church")
    end

    def set_joined_at
      self.joined_at ||= Time.current
    end
end
