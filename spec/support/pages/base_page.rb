class BasePage < SitePrism::Page
  def sign_in(email, password)
    visit '/sign_in'
    within('#clearance') do
      fill_in 'session_email', with: email
      fill_in 'session_password', with: password
      click_button I18n.t('helpers.submit.session.submit')
    end
  end

  def sign_out
    click_button I18n.t('layouts.application.sign_out')
  end

  def signed_in?
    has_css?('button', text: I18n.t('layouts.application.sign_out'))
  end

  def signed_out?
    has_content?(I18n.t('layouts.application.sign_in'))
  end
end
