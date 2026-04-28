module SessionTestHelper
  def sign_in_as(user)
    Current.user = user
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  def sign_in_to_church_as(user, church)
    sign_in_as(user)
    patch current_church_path, params: { church_id: church.id }
  end

  def sign_out
    Current.user = nil
    Current.church = nil
    Current.church_membership = nil
    delete session_path
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
