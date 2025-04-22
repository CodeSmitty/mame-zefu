class PasswordsController < Clearance::PasswordsController
  include Pundit::Authorization
  before_action :set_mailer_host
  after_action :skip_authorization

  private

  def set_mailer_host
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end
end
