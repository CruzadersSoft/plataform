require "test_helper"

class Events::PublishEventTest < ActiveSupport::TestCase
  test "publishes a draft event" do
    event = events(:worship_rehearsal)
    assert event.draft?

    result = Events::PublishEvent.new(event: event, actor: users(:one)).call

    assert result.success?
    assert event.reload.published?
  end

  test "fails if event is already cancelled" do
    event = events(:sunday_service)
    event.update!(status: :cancelled)

    result = Events::PublishEvent.new(event: event, actor: users(:one)).call

    assert_not result.success?
    assert_includes result.errors, "Evento não pode ser publicado no estado atual."
  end

  test "does not change an already published event" do
    event = events(:sunday_service)
    assert event.published?

    result = Events::PublishEvent.new(event: event, actor: users(:one)).call

    assert result.success?
    assert event.reload.published?
  end
end
