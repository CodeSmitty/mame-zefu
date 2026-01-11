class Recipe < ApplicationRecord
  MAX_IMAGE_SIZE = 5.megabytes

  validates :name, presence: true
  has_and_belongs_to_many :categories
  belongs_to :user
  has_one_attached :image
  attr_accessor :image_src, :remove_image

  before_save :attach_image_from_url, if: -> { image_src.present? && !image.attached? }
  before_save :delete_image, if: -> { ActiveModel::Type::Boolean.new.cast(remove_image) }
  before_save :purge_if_replacing

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

  private

  def delete_image
    image.purge if image.attached?
  end

  def purge_if_replacing
    return unless ActiveModel::Type::Boolean.new.cast(remove_image) && image.attached?
    
    image.purge if image.attached?
  end

  def attach_image_from_url
    return unless url?(image_src)

    downloaded_file = Down.download(image_src, max_size: MAX_IMAGE_SIZE)
    image.attach(
      io: downloaded_file,
      filename: File.basename(image_src)
    )
  rescue Down::Error => e
    errors.add(:image, "couldn't be downloaded: #{e.message}")
    throw :abort
  end

  def url?(string)
    uri = URI.parse(string)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end
end
