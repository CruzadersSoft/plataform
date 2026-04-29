class Announcement < ApplicationRecord
  belongs_to :church
  belongs_to :creator, class_name: "User", foreign_key: :created_by

  enum :audience_type, { all_members: 0, leaders_only: 1 }, default: :all_members
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft

  validates :title, presence: true
  validates :body, presence: true
end
