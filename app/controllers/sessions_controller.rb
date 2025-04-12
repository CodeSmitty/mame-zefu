class SessionsController < Clearance::SessionsController
  include Pundit::Authorization
  after_action :skip_authorization
end
