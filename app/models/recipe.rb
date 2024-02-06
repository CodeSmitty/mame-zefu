class Recipe < ApplicationRecord
  validates :name, presence: true
  has_and_belongs_to_many :categories
  accepts_nested_attributes_for :categories

  def save_categories
    categories.map do |category|
      Category.find_or_create_by(name: category.name.strip)
    end
  end

  scope :sorted, -> { order(name: :asc) }
end
