module Admin
  class ApplicationController < Administrate::ApplicationController
    include Clearance::Controller

    before_action :require_login
  end
end
