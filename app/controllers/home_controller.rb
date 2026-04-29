class HomeController < ApplicationController
  def index
    @church = Current.church
    @membership = Current.church_membership

    return redirect_to assignments_path if @membership.pure_volunteer?

    @invitation_code = active_invitation_code if @membership.church_admin?
    @pending_tasks = pending_tasks.limit(5)
    @pending_tasks_count = pending_tasks.count
    @recent_announcements = policy_scope(Announcement).order(created_at: :desc).limit(5)
    @unread_notifications = unread_notifications.limit(5)
    @unread_notifications_count = unread_notifications.count
  end

  private
    def active_invitation_code
      @church.church_invitation_codes.acceptable.order(created_at: :desc).first
    end

    def pending_tasks
      policy_scope(Task)
        .includes(:department, :assigned_user)
        .where(status: [ Task.statuses[:pending], Task.statuses[:in_progress] ])
        .order(due_at: :asc, created_at: :desc)
    end

    def unread_notifications
      @church.notifications.unread.where(user: Current.user).order(created_at: :desc)
    end
end
