class Skill < ApplicationRecord
  # Habilidades esta pausada como funcionalidade de produto por enquanto.
  # Manter apenas o modelo/base para uma retomada futura.
  attribute :active, :boolean, default: true

  belongs_to :church
  has_many :event_requirements, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :church_id }

  scope :active, -> { where(active: true) }
end
