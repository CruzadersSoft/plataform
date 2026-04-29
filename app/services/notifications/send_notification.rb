module Notifications
  class SendNotification
    def initialize(church:, user:, type:, title:, body: nil, related: nil)
      @church  = church
      @user    = user
      @type    = type
      @title   = title
      @body    = body
      @related = related
    end

    def call
      @church.notifications.create!(
        user: @user,
        notification_type: @type,
        title: @title,
        body: @body,
        related_type: @related&.class&.name,
        related_id: @related&.id
      )
    end
  end
end
