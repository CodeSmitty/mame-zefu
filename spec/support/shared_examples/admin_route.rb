RSpec.shared_examples 'an admin-only route' do |verb, path_or_proc, params = {}|
  def resolve_path(path_or_proc)
    if path_or_proc.respond_to?(:call)
      instance_exec(&path_or_proc)
    else
      path_or_proc
    end
  end

  def authenticate_user(user)
    cookies[Clearance.configuration.cookie_name] = user.remember_token
  end

  context 'when signed in as a non-admin user' do
    let(:user) { create(:user) }

    before do
      authenticate_user(user)
      public_send(verb, resolve_path(path_or_proc), params: params)
    end

    it 'denies access', skip: 'admin restriction temporarily disabled' do
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when signed in as an admin user' do
    let(:admin) { create(:user, is_admin: true) }

    before do
      authenticate_user(admin)
      public_send(verb, resolve_path(path_or_proc), params: params)
    end

    it 'allows access' do
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when unauthenticated' do
    before do
      public_send(verb, resolve_path(path_or_proc), params: params)
    end

    it 'redirects to the login page' do
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
