class UsersController < Clearance::UsersController
  skip_after_action :verify_pundit_authorization
end
