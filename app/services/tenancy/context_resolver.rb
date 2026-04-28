module Tenancy
  class ContextResolver
    def initialize(user:, church_id:)
      @user = user
      @church_id = church_id
    end

    def call
      membership = user&.church_memberships&.active&.includes(:church)&.find_by(church_id: church_id)
      return ApplicationServiceResult.new(success: false, church: nil, membership: nil) unless membership&.church&.active?

      ApplicationServiceResult.new(success: true, church: membership.church, membership: membership)
    end

    private
      attr_reader :user, :church_id
  end
end
