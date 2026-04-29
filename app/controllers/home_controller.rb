class HomeController < ApplicationController
  def index
    @church = Current.church
    @membership = Current.church_membership

    return redirect_to assignments_path if @membership.pure_volunteer?

    @invitation_code = active_invitation_code if @membership.church_admin?
  end

  private
    def active_invitation_code
      @church.church_invitation_codes.acceptable.order(created_at: :desc).first
    end
end
