require 'rails_helper'
require 'support/features/clearance_helpers'

RSpec.feature 'Visitor resets password' do
  before { ActionMailer::Base.deliveries.clear }

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  scenario 'by navigating to the page' do
    visit sign_in_path

    click_link_or_button I18n.t('sessions.form.forgot_password')
    expect(page).to have_current_path(new_password_path)
  end

  scenario 'with valid email' do
    user = user_with_reset_password
    expect_page_to_display_change_password_message
    expect_reset_notification_to_be_sent_to user
  end

  scenario 'with non-user account' do
    reset_password_for 'unkemail@gmail.com'

    expect_page_to_display_change_password_message
    expect_mailer_to_have_no_deliveries
  end

  private

  def expect_reset_notification_to_be_sent_to(user)
    expect(user.confirmation_token).not_to be_blank
    expect_mailer_to_have_delivery(
      user.email,
      'password',
      user.confirmation_token
    )
  end

  def expect_page_to_display_change_password_message
    expect(page).to have_content I18n.t('passwords.create.description')
  end

  def expect_mailer_to_have_delivery(recipient, subject, body) # rubocop:disable Metrics/AbcSize
    expect(ActionMailer::Base.deliveries).not_to be_empty

    message = ActionMailer::Base.deliveries.any? do |email|
      email.to == [recipient] &&
        email.subject =~ /#{subject}/i &&
        email.html_part.body =~ /#{body}/ &&
        email.text_part.body =~ /#{body}/
    end

    expect(message).to be_truthy
  end

  def expect_mailer_to_have_no_deliveries
    expect(ActionMailer::Base.deliveries).to be_empty
  end
end
