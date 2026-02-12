require 'rails_helper'

RSpec.feature 'Admin link in navbar' do
  given(:home_page) { HomePage.new }

  scenario 'is hidden for non-admin users' do
    user = create(:user)

    visit root_path(as: user)

    expect(home_page).to have_no_admin_link
  end

  scenario 'is visible for admin users' do
    admin = create(:user, is_admin: true)

    visit root_path(as: admin)

    expect(home_page).to have_admin_link
  end
end
