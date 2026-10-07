class Todo < ApplicationRecord
  belongs_to :user

  validates :title, presence: true, length: { maximum: 120 }
end
