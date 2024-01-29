class Recipe < ApplicationRecord
  validates :name, presence: true

  has_and_belongs_to_many :categories, join_table: 'categories_recipes', foreign_key: true

  scope :sorted, -> { order(name: :asc) }
end
