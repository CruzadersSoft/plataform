module Events
  class CreateEvent
    def initialize(church:, params:, actor:)
      @church = church
      @params = params
      @actor  = actor
    end

    def call
      event = @church.events.new(event_params.merge(created_by: @actor.id))

      if event.save
        ApplicationServiceResult.new(success: true, event: event)
      else
        ApplicationServiceResult.new(success: false, event: event, errors: event.errors.full_messages)
      end
    end

    private

    def event_params
      @params.slice(:title, :event_type, :starts_at, :ends_at, :location, :department_id, :notes)
    end
  end
end
