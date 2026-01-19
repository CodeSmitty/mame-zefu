require 'rails_helper'

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:user) { create(:user) }
  let(:record) { double(Object, user: user) } # rubocop:disable RSpec/VerifiedDoubles

  describe 'default permissions' do
    it { is_expected.not_to be_index }
    it { is_expected.not_to be_show }
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_new }
    it { is_expected.not_to be_update }
    it { is_expected.not_to be_edit }
    it { is_expected.not_to be_destroy }
  end

  describe ApplicationPolicy::Scope do
    subject { described_class.new(user, []) }

    it 'raises NoMethodError when resolve is called' do
      expect { policy.resolve }.to raise_error(NoMethodError)
    end
  end
end
