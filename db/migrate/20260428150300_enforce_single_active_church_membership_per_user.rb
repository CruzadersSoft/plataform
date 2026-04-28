class EnforceSingleActiveChurchMembershipPerUser < ActiveRecord::Migration[8.1]
  def up
    duplicates = select_all(<<~SQL.squish)
      SELECT user_id, GROUP_CONCAT(id) AS ids
      FROM church_memberships
      WHERE status = 0
      GROUP BY user_id
      HAVING COUNT(*) > 1
    SQL

    duplicates.each do |row|
      ids = row["ids"].split(",").map(&:to_i).sort
      ids_to_inactivate = ids.drop(1)
      next if ids_to_inactivate.empty?

      execute <<~SQL.squish
        UPDATE church_memberships
        SET status = 2, updated_at = CURRENT_TIMESTAMP
        WHERE id IN (#{ids_to_inactivate.join(",")})
      SQL
    end

    add_index :church_memberships,
      :user_id,
      unique: true,
      where: "status = 0",
      name: "index_church_memberships_on_active_user_id"
  end

  def down
    remove_index :church_memberships, name: "index_church_memberships_on_active_user_id"
  end
end
