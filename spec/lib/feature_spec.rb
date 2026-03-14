# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Feature do
  describe '.sync_features' do
    let(:existing_feature_keys) { %w[recipe_extraction legacy_feature] }
    let(:existing_features) do
      existing_feature_keys.map { |key| instance_double(Flipper::Feature, key:) }
    end

    before do
      allow(Flipper).to receive(:features).and_return(existing_features)
      allow(Flipper).to receive(:add)
      allow(Flipper).to receive(:remove)
    end

    it 'adds missing managed features and removes stale features' do
      described_class.sync_features

      expect(Flipper).to have_received(:add).with(:recipe_extraction_disabled)
      expect(Flipper).to have_received(:remove).with(:legacy_feature)
    end

    it 'does not re-add already existing managed features' do
      described_class.sync_features

      expect(Flipper).not_to have_received(:add).with(:recipe_extraction)
    end
  end

  describe '.recipe_extraction_enabled?' do
    let(:user) { build_stubbed(:user) }

    it 'returns true when main flag is enabled and disabled flag is off' do
      allow(Flipper).to receive(:enabled?).with(:recipe_extraction, user).and_return(true)
      allow(Flipper).to receive(:enabled?).with('recipe_extraction_disabled', user).and_return(false)

      expect(described_class.recipe_extraction_enabled?(user)).to be(true)
    end

    it 'returns false when main flag is disabled' do
      allow(Flipper).to receive(:enabled?).with(:recipe_extraction, user).and_return(false)
      allow(Flipper).to receive(:enabled?).with('recipe_extraction_disabled', user).and_return(false)

      expect(described_class.recipe_extraction_enabled?(user)).to be(false)
    end

    it 'returns false when user is explicitly disabled' do
      allow(Flipper).to receive(:enabled?).with(:recipe_extraction, user).and_return(true)
      allow(Flipper).to receive(:enabled?).with('recipe_extraction_disabled', user).and_return(true)

      expect(described_class.recipe_extraction_enabled?(user)).to be(false)
    end
  end
end
