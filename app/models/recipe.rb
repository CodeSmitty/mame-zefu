class Recipe < ApplicationRecord
    validates :name, length:{minimum:3, maximum:25}, presense:true
end
