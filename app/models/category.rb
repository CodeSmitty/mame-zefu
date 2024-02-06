class Category < ApplicationRecord
  validates :name, presence: true

  has_and_belongs_to_many :recipes
  accepts_nested_attributes_for :recipes
end
