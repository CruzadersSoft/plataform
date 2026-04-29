class Church::NotificationsController < ApplicationController
  before_action :set_notification, only: %i[show update]

  def index
    authorize Notification
    @read_filter = params[:read].presence
    @notifications = policy_scope(Notification)
    @notifications = @notifications.unread if @read_filter == "unread"
    @notifications = @notifications.where.not(read_at: nil) if @read_filter == "read"
    @notifications = @notifications.order(Arel.sql("read_at IS NOT NULL"), created_at: :desc)
  end

  def show
    authorize @notification
    @notification.mark_read!
  end

  def update
    authorize @notification
    @notification.mark_read!

    redirect_to notifications_path, notice: "Notificação marcada como lida."
  end

  private

    def set_notification
      @notification = Current.church.notifications.where(user: Current.user).find(params[:id])
    end
end
