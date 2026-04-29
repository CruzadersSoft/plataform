class Event < ApplicationRecord
  belongs_to :church
  belongs_to :department, optional: true
  belongs_to :creator, class_name: "User", foreign_key: :created_by, optional: true

  has_many :event_requirements, dependent: :destroy
  has_many :schedule_assignments, dependent: :destroy

  enum :status, { draft: 0, published: 1, cancelled: 2 }, default: :draft
  enum :event_type, { service: 0, rehearsal: 1, meeting: 2, other: 3 }

  validates :title, presence: true
  validates :event_type, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :ends_at_after_starts_at
  validate :department_belongs_to_church

  private

  def ends_at_after_starts_at
    return unless starts_at && ends_at
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end

  def department_belongs_to_church
    return if church.blank? || department.blank?
    return if department.church_id == church_id

    errors.add(:department, "must belong to the same church")
  end
end
