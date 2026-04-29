module Events
  class PublishEvent
    def initialize(event:, actor:)
      @event = event
      @actor = actor
    end

    def call
      return failure("Evento não pode ser publicado no estado atual.") if @event.cancelled?

      @event.published!
      ApplicationServiceResult.new(success: true, event: @event)
    rescue ActiveRecord::RecordInvalid => e
      ApplicationServiceResult.new(success: false, event: @event, errors: e.record.errors.full_messages)
    end

    private

    def failure(message)
      ApplicationServiceResult.new(success: false, event: @event, errors: [ message ])
    end
  end
end
