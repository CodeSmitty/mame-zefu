class HomePage < BasePage
  set_url '/'

  element :new_recipe_link, 'a[href="/recipes/new"]'
  element :web_search_link, 'a[href="/recipes/web_search"]'
  element :archive_upload_link, 'a[href="/recipes/archive/upload"]'
  element :sign_in_link, 'a[href="/sign_in"]'
  element :sign_out_button, 'button', text: I18n.t('layouts.application.sign_out')

  def click_new_recipe
    new_recipe_link.click
  end

  def signed_in?
    has_css?('button', text: I18n.t('layouts.application.sign_out'))
  end

  def signed_out?
    has_content?(I18n.t('layouts.application.sign_in'))
  end
end
