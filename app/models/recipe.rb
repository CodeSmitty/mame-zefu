class Recipe < ApplicationRecord
  validates :name, presence: true
  has_and_belongs_to_many :categories

  def category_names
    categories.pluck(:name)
  end

  def category_names=(category_names)
    self.category_ids = Category.from_names(category_names).pluck(:id)
  end

  scope :with_text, lambda { |query|
    return if query.blank?

    san_query = "%#{sanitize_sql_like(query)}%"
    where('recipes.name ILIKE ?', san_query)
      .or(where('recipes.directions ILIKE ?', san_query))
      .or(where('recipes.ingredients ILIKE ?', san_query))
      .or(where('recipes.notes ILIKE ?', san_query))
  }

  scope :in_categories, lambda { |category_names|
    return if category_names.blank?

    joins(:categories)
      .where(categories: { name: category_names })
      .group('recipes.id')
      .having('count(distinct categories.id) = ?', category_names.size)
  }

  scope :sorted, -> { order(name: :asc) }
end
