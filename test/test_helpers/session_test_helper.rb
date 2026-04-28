module SessionTestHelper
  def sign_in_as(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies["session_id"] = cookie_jar[:session_id]
    end
  end

  def sign_in_to_church_as(user, church)
    sign_in_as(user)
    patch current_church_path, params: { church_id: church.id }
  end

  def sign_out
    Current.session&.destroy!
    Current.church = nil
    Current.church_membership = nil
    cookies.delete("session_id")
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
