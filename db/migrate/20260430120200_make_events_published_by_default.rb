class MakeEventsPublishedByDefault < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE events
      SET status = CASE
        WHEN status = 2 THEN 1
        ELSE 0
      END
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE events
      SET status = CASE
        WHEN status = 1 THEN 2
        ELSE 1
      END
    SQL
  end
end
