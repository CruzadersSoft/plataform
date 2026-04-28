module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.user ||= find_user_by_session
    end

    def find_user_by_session
      User.find_by(id: session[:user_id]) if session[:user_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      requested_url = session.delete(:return_to_after_authenticating)
      return default_after_authentication_url if requested_url.blank?
      return default_after_authentication_url if platform_url?(requested_url) && !Current.user&.platform_admin?

      requested_url
    end

    def default_after_authentication_url
      Current.user&.platform_admin? ? platform_root_url : root_url
    end

    def platform_url?(url)
      URI.parse(url).path.start_with?(platform_root_path)
    rescue URI::InvalidURIError
      false
    end

    def start_new_session_for(user)
      Current.user = user
      session[:user_id] = user.id
    end

    def terminate_session
      session.delete(:user_id)
      Current.reset
    end
end
