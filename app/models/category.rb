class Category < ApplicationRecord
  validates :name, presence: true
  validates :name, uniqueness: { scope: :user_id, case_sensitive: false }

  belongs_to :user
  has_and_belongs_to_many :recipes

  def self.from_names(names, user:)
    names.map do |name|
      user.categories.where('LOWER(name) = ?', name.downcase).first_or_create(name: name)
    end
  end
end
