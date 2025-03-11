Clearance.configure do |config|
  config.routes = true
  config.mailer_sender = ENV['TEST_SENDER_EMAIL']
  config.rotate_csrf_on_sign_in = true
end
