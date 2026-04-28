module Memberships
  class JoinChurchByInvitation
    def initialize(actor:, code:)
      @actor = actor
      @code = code
    end

    def call
      invitation = ChurchInvitationCode.find_by(code: normalized_code)
      return failure unless invitation&.acceptable?

      existing_membership = invitation.church.church_memberships.find_by(user: actor)
      return failure(membership: existing_membership) if existing_membership
      return failure(errors: [ "Usuario ja possui uma igreja ativa." ]) if active_church_membership

      membership = invitation.church.church_memberships.create!(
        user: actor,
        church_role: invitation.church_role,
        status: :active,
        invited_by_id: invitation.created_by_id
      )

      ApplicationServiceResult.new(success: true, church: invitation.church, membership: membership)
    rescue ActiveRecord::RecordInvalid => error
      failure(errors: error.record.errors.full_messages)
    end

    private
      attr_reader :actor, :code

      def normalized_code
        code.to_s.strip.upcase
      end

      def active_church_membership
        actor.church_memberships.active.includes(:church).detect { |membership| membership.church.active? }
      end

      def failure(membership: nil, errors: [])
        ApplicationServiceResult.new(success: false, church: nil, membership: membership, errors: errors)
      end
  end
end
