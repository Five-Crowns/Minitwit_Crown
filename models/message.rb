class Message < ActiveRecord::Base
  # Relationships
  belongs_to :author, class_name: "User", foreign_key: :author_id

  # Validations (optional)
  validates :text, presence: true
  validates :author_id, presence: true
end
