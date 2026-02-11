class Recipe < ApplicationRecord
  MAX_IMAGE_SIZE = 5.megabytes

  validates :name, presence: true
  has_and_belongs_to_many :categories
  belongs_to :user
  has_one_attached :image
  attr_accessor :image_src
  attr_accessor :pending_category_names

  before_save :ensure_pending_categories
  before_save :attach_image_from_url, if: -> { image_src.present? && !image.attached? }
  before_save :normalize_line_endings

  def category_names
    return pending_category_names unless pending_category_names.nil?

    categories.pluck(:name)
  end

  def category_names=(category_names)
    self.pending_category_names = Array(category_names).compact_blank
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

  def attach_image_from_url
    return unless url?(image_src)

    downloaded_file = Down.download(image_src, max_size: MAX_IMAGE_SIZE)
    image.attach(
      io: downloaded_file,
      filename: File.basename(image_src)
    )
  rescue Down::Error => e
    Rails.logger.error("Failed to download image from #{image_src}: #{e.message}")
  end

  def url?(string)
    uri = URI.parse(string)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def normalize_line_endings
    %w[directions ingredients notes].each do |field|
      text = send(field)
      self[field] = text&.gsub("\r\n", "\n")&.gsub("\r", "\n") if text.present?
    end
  end

  def ensure_pending_categories
    return if pending_category_names.nil?

    self.category_ids = Category.from_names(pending_category_names, user:).pluck(:id)
    self.pending_category_names = nil
  end
end
