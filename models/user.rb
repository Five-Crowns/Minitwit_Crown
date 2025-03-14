# models/user.rb
require 'active_record'
class User < ActiveRecord::Base
  # Relationships
  has_many :messages, foreign_key: :author_id
  has_many :followers, foreign_key: :who_id
  has_many :following, class_name: "Follower", foreign_key: :whom_id

  # Validations (optional, add if needed)
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :pw_hash, presence: true
end