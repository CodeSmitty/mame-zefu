module Admin
  class ApplicationController < Administrate::ApplicationController
    include Clearance::Controller

    before_action :require_login
    # before_action :require_admin

    # private

    # def require_admin
    #   return if current_user&.is_admin?

    #   render file: Rails.root.join(Rails.public_path, '404.html'), status: :not_found, layout: false
    # end
  end
end
