class BackfillChurchInvitationCodes < ActiveRecord::Migration[8.1]
  class Church < ActiveRecord::Base
    has_many :church_memberships, class_name: "BackfillChurchInvitationCodes::ChurchMembership"
    has_many :church_invitation_codes, class_name: "BackfillChurchInvitationCodes::ChurchInvitationCode"
  end

  class ChurchMembership < ActiveRecord::Base
    belongs_to :church, class_name: "BackfillChurchInvitationCodes::Church"
  end

  class ChurchInvitationCode < ActiveRecord::Base
    belongs_to :church, class_name: "BackfillChurchInvitationCodes::Church"
  end

  def up
    Church.find_each do |church|
      next if church.church_invitation_codes.where(status: 0).where("expires_at IS NULL OR expires_at > ?", Time.current).exists?

      creator_id = church.church_memberships.where(status: 0, church_role: 2).pick(:user_id) ||
        church.church_memberships.where(status: 0).pick(:user_id)
      next unless creator_id

      church.church_invitation_codes.create!(
        code: unique_code,
        church_role: 0,
        status: 0,
        created_by_id: creator_id,
        created_at: Time.current,
        updated_at: Time.current
      )
    end
  end

  def down
    # No-op: generated invitation codes may have been shared with real users.
  end

  private
    def unique_code
      loop do
        code = SecureRandom.alphanumeric(10).upcase
        break code unless ChurchInvitationCode.exists?(code: code)
      end
    end
end
