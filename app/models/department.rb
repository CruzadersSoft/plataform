class Department < ApplicationRecord
  belongs_to :church
  has_many :department_memberships, dependent: :destroy
  has_many :users, through: :department_memberships

  validates :name, presence: true, uniqueness: { scope: :church_id }
end
