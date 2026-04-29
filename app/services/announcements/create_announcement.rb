module Announcements
  class CreateAnnouncement
    def initialize(church:, params:, actor:)
      @church = church
      @params = params
      @actor  = actor
    end

    def call
      announcement = @church.announcements.new(announcement_params.merge(created_by: @actor.id))

      if announcement.save
        ApplicationServiceResult.new(success: true, announcement: announcement)
      else
        ApplicationServiceResult.new(success: false, announcement: announcement, errors: announcement.errors.full_messages)
      end
    end

    private

    def announcement_params
      @params.slice(:title, :body, :audience_type)
    end
  end
end
