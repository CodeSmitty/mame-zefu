# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe '#flipper_id' do
    it 'returns the user email' do
      user = build_stubbed(:user, email: 'test@example.com')

      expect(user.flipper_id).to eq('test@example.com')
    end
  end
end
