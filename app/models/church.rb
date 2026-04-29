class Church < ApplicationRecord
  has_many :church_memberships, dependent: :destroy
  has_many :users, through: :church_memberships
  has_many :church_invitation_codes, dependent: :destroy
  has_many :departments, dependent: :destroy
  has_many :department_memberships, dependent: :destroy
  has_many :skills, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :event_requirements, dependent: :destroy
  has_many :schedule_assignments, dependent: :destroy
  has_many :unavailabilities, dependent: :destroy

  enum :status, { active: 0, inactive: 1, suspended: 2 }

  normalizes :slug, with: ->(slug) { slug.to_s.strip.parameterize }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :timezone, presence: true
end
