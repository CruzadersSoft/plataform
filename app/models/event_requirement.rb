class EventRequirement < ApplicationRecord
  # Detalhe tecnico interno: a UI atual trabalha com convocacoes diretas,
  # mas mantemos requisitos separados de designacoes por regra arquitetural.
  DEFAULT_INVITATION_ROLE = "Convocado"

  belongs_to :church
  belongs_to :event
  belongs_to :skill, optional: true

  has_many :schedule_assignments, dependent: :destroy

  validates :role_name, presence: true
  validates :required_quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validate :event_belongs_to_church
  validate :skill_belongs_to_church

  private

  def event_belongs_to_church
    return if church.blank? || event.blank?
    return if event.church_id == church_id

    errors.add(:event, "must belong to the same church")
  end

  def skill_belongs_to_church
    return if church.blank? || skill.blank?
    return if skill.church_id == church_id

    errors.add(:skill, "must belong to the same church")
  end
end
