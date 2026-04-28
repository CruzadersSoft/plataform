class Church::MembersController < ApplicationController
  before_action :set_membership, only: :show

  def index
    authorize ChurchMembership, policy_class: MemberPolicy
    @memberships = policy_scope(ChurchMembership, policy_scope_class: MemberPolicy::Scope).includes(:user).order("users.name")
  end

  def show
    authorize @membership, policy_class: MemberPolicy
    @department_memberships = @membership.user.department_memberships.active.where(church: Current.church).includes(:department)
  end

  private
    def set_membership
      @membership = Current.church.church_memberships.active.find_by!(user_id: params[:id])
    end
end
