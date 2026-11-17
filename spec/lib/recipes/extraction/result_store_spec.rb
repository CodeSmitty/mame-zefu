# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Extraction::ResultStore do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:recipe) do
    Recipe.new(
      name: 'Toast',
      ingredients: "Bread\nButter",
      directions: "Toast bread\nSpread butter",
      category_names: ['Breakfast']
    )
  end

  describe '.store and .fetch' do
    subject(:token) { described_class.store(user:, recipe:) }

    let(:expected_payload) do
      {
        name: 'Toast',
        ingredients: "Bread\nButter",
        directions: "Toast bread\nSpread butter",
        category_names: ['Breakfast']
      }
    end

    it 'stores and returns extracted recipe attributes' do
      expect(described_class.fetch(user:, token:)).to include(expected_payload)
    end

    it 'retains the payload for a preview refresh' do
      described_class.fetch(user:, token:)

      expect(described_class.fetch(user:, token:)).to include(expected_payload)
    end

    it 'does not expose the payload to another user' do
      expect(described_class.fetch(user: create(:user), token:)).to be_nil
    end

    it 'expires the payload after 15 minutes' do
      token

      travel 16.minutes do
        expect(described_class.fetch(user:, token:)).to be_nil
      end
    end
  end
end
