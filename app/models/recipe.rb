class Recipe < ApplicationRecord
  validates :name, presence: true
  has_and_belongs_to_many :categories

  def category_names
    categories.pluck(:name)
  end

  def category_names=(category_names)
    self.category_ids = Category.from_names(category_names).pluck(:id)
  end

  scope :search, -> (params){
    return all if params.blank?
    query = "%#{sanitize_sql_like(params)}%"
    where('name ILIKE ?', query)
      .or(where('directions ILIKE ?', query))
      .or(where('ingredients ILIKE ?', query))
      .or(where('notes ILIKE ?', query))
  }

  scope :category_search, ->(category_names){
    return all if category_names.blank?
    category_name = "%#{sanitize_sql_like(category_names)}%"
    joins(:categories).where('categories.name  ILIKE ?', category_name)
  }

  scope :sorted, -> { order(name: :asc) }
end