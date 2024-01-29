class Category < ApplicationRecord
  validates :name, presence: true

  has_and_belongs_to_many :recipes, join_table: 'categories_recipes', foreign_key: true
end
