class Category < ApplicationRecord
  validates :name, presence: true

  has_and_belongs_to_many :recipes

  def self.from_names(names)
    names.map do |name|
      find_or_create_by(name:)
    end
  end
end
