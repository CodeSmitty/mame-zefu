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
    return if params.blank?

    query = "%#{sanitize_sql_like(params)}%"
    where('recipes.name ILIKE ?', query)
      .or(where('recipes.directions ILIKE ?', query))
      .or(where('recipes.ingredients ILIKE ?', query))
      .or(where('recipes.notes ILIKE ?', query))
  }

  scope :category_search, ->(category_names){
    return if category_names.blank?

    joins(:categories)
      .where(categories: { name: category_names })
      .group('recipes.id')
      .having('count(distinct categories.id) = ?', category_names.size)
  }

  scope :sorted, -> { order(name: :asc) }
end