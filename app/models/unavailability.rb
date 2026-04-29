class Unavailability < ApplicationRecord
  belongs_to :church
  belongs_to :user

  enum :status, { active: 0, cancelled: 1 }, default: :active

  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :ends_at_after_starts_at

  scope :active, -> { where(status: :active) }

  private

  def ends_at_after_starts_at
    return unless starts_at && ends_at
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end
end
