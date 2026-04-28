class Church < ApplicationRecord
  has_many :church_memberships, dependent: :destroy
  has_many :users, through: :church_memberships
  has_many :church_invitation_codes, dependent: :destroy

  enum :status, { active: 0, inactive: 1, suspended: 2 }

  normalizes :slug, with: ->(slug) { slug.to_s.strip.parameterize }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :timezone, presence: true
end
