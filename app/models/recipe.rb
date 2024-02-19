class Recipe < ApplicationRecord
  validates :name, presence: true
  has_and_belongs_to_many :categories

  def category_names
    categories.pluck(:name)
  end

  def category_names=(category_names)
    self.category_ids = Category.from_names(category_names).pluck(:id)
  end

  scope :sorted, -> { order(name: :asc) }
end
