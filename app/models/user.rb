class User < ApplicationRecord
  include Clearance::User
  has_many :recipes, dependent: nil
end
