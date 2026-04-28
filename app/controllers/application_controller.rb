class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_church
  before_action :require_current_church

  helper_method :current_user, :current_church

  private
    def current_user
      Current.user
    end

    def current_church
      Current.church
    end

    def set_current_church
      return unless Current.user

      return restore_current_church_from_session if session[:church_id].present?

      restore_single_active_church
    end

    def restore_current_church_from_session
      result = Tenancy::ContextResolver.new(user: Current.user, church_id: session[:church_id]).call
      if result.success?
        Current.church = result.church
        Current.church_membership = result.membership
      else
        session.delete(:church_id)
        Current.church = nil
        Current.church_membership = nil
        restore_single_active_church
      end
    end

    def restore_single_active_church
      return if Current.user.platform_admin?

      memberships = Current.user
        .church_memberships
        .active
        .includes(:church)
        .select { |membership| membership.church.active? }

      return unless memberships.one?

      membership = memberships.first
      session[:church_id] = membership.church_id
      Current.church = membership.church
      Current.church_membership = membership
    end

    def require_current_church
      return unless Current.user
      return if Current.church.present?
      return if controller_path.start_with?("platform/")
      return if controller_name == "onboarding"
      return if controller_name == "current_churches"
      return if controller_name.in?(%w[sessions users passwords])

      return redirect_to platform_root_path if Current.user.platform_admin?

      redirect_to onboarding_path
    end

    def activate_church!(church)
      session[:church_id] = church.id
      result = Tenancy::ContextResolver.new(user: Current.user, church_id: church.id).call
      Current.church = result.church if result.success?
      Current.church_membership = result.membership if result.success?
    end

    def user_not_authorized
      return redirect_to root_path if controller_path.start_with?("platform/")

      redirect_to root_path, alert: "Voce nao tem permissao para acessar esta area."
    end
end
