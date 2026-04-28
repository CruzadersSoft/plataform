module Onboarding
  class CreateChurch
    def initialize(actor:, params:)
      @actor = actor
      @params = params
    end

    def call
      return active_church_failure if active_church_membership

      church = Church.new(church_params)
      membership = nil
      invitation_code = nil

      Church.transaction do
        church.save!
        membership = church.church_memberships.create!(
          user: actor,
          church_role: :church_admin,
          status: :active
        )
        invitation_code = church.church_invitation_codes.create!(
          created_by: actor,
          church_role: :volunteer,
          status: :active
        )
      end

      ApplicationServiceResult.new(success: true, church: church, membership: membership, invitation_code: invitation_code)
    rescue ActiveRecord::RecordInvalid
      ApplicationServiceResult.new(success: false, church: church, membership: membership, invitation_code: invitation_code, errors: church.errors.full_messages)
    end

    private
      attr_reader :actor, :params

      def church_params
        params.slice(:name, :slug, :legal_name, :email, :phone, :timezone)
      end

      def active_church_membership
        actor.church_memberships.active.includes(:church).detect { |membership| membership.church.active? }
      end

      def active_church_failure
        ApplicationServiceResult.new(success: false, church: active_church_membership.church, membership: nil, invitation_code: nil, errors: [ "Usuario ja possui uma igreja ativa." ])
      end
  end
end
