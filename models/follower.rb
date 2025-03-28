require "active_record"
class Follower < ActiveRecord::Base
  # Relationships
  belongs_to :who, class_name: "User", foreign_key: :who_id
  belongs_to :whom, class_name: "User", foreign_key: :whom_id

  # Validations (optional)
  validates :who_id, presence: true
  validates :whom_id, presence: true
  validates_uniqueness_of :who_id, scope: :whom_id  # Ensures a user cannot follow the same user multiple times
end
