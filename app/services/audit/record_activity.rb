module Audit
  class RecordActivity
    def initialize(church:, actor:, entity:, action:, metadata: {}, ip_address: nil)
      @church     = church
      @actor      = actor
      @entity     = entity
      @action     = action
      @metadata   = metadata
      @ip_address = ip_address
    end

    def call
      activity_log = @church.activity_logs.create!(
        actor_user: @actor,
        entity_type: @entity.class.name,
        entity_id: @entity.id,
        action: @action,
        metadata_json: @metadata,
        ip_address: @ip_address
      )

      ApplicationServiceResult.new(success: true, activity_log: activity_log)
    rescue ActiveRecord::RecordInvalid => e
      ApplicationServiceResult.new(success: false, activity_log: e.record, errors: e.record.errors.full_messages)
    end
  end
end
