Clearance.configure do |config|
  config.routes = false
  config.mailer_sender = ENV['MAIL_SENDER'] if ENV['MAIL_SENDER'].present? 
  config.rotate_csrf_on_sign_in = true
end
