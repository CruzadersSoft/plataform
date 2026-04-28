class Current < ActiveSupport::CurrentAttributes
  attribute :session, :church, :church_membership

  delegate :user, to: :session, allow_nil: true
end
