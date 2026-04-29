class Notification < ApplicationRecord
  belongs_to :church
  belongs_to :user

  validates :notification_type, presence: true
  validates :title, presence: true
  validate :user_is_active_church_member

  scope :unread, -> { where(read_at: nil) }

  def mark_read!
    update!(read_at: Time.current) if read_at.nil?
  end

  private

    def user_is_active_church_member
      return if church.blank? || user.blank?
      return if church.church_memberships.active.exists?(user: user)

      errors.add(:user, "must be an active member of the church")
    end
end
