require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox') if ENV['CHROME_NO_SANDBOX'] == '1'
  options.binary = ENV['CHROME_BIN'] if ENV['CHROME_BIN'].present?

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome
WebMock.disable_net_connect!(allow_localhost: true)
