class Recipe < ApplicationRecord
  validates :name, presence: true
  has_and_belongs_to_many :categories

  def category_names
    categories.pluck(:name)
  end

  def category_names=(category_names)
    self.category_ids = Category.from_names(category_names).pluck(:id)
  end

  def self.search(params)
    return all if params[:query].blank?

    query = "%#{sanitize_sql_like(params[:query])}%"

    where('name ILIKE ?', query)
      .or(where('directions ILIKE ?', query))
      .or(where('ingredients ILIKE ?', query))
      .or(where('notes ILIKE ?', query))
  end

  scope :sorted, -> { order(name: :asc) }
end
