module Admin
  class CategoriesController < Admin::ApplicationController
    def default_sorting_attribute
      :name
    end
  end
end
