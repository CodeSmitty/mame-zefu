Clearance.configure do |config|
  config.routes = true
  config.mailer_sender = ENV.fetch('TEST_SENDER_EMAIL', nil)
  config.rotate_csrf_on_sign_in = true
end
