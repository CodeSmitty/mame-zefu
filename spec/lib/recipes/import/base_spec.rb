# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Import::Base do
  subject(:import) { test_class.new(document, source) }

  let(:document) { Nokogiri::HTML('<html><body>Test</body></html>') }
  let(:source) { 'https://example.com/recipe' }

  let(:recipe_fields) do
    {
      name: 'Test Recipe',
      yield: '4 servings',
      prep_time: '30',
      cook_time: '60',
      category_names: %w[Main Italian],
      description: 'A test recipe',
      ingredients: 'Ingredient 1',
      directions: 'Step 1',
      notes: 'Some notes',
      rating: 5,
      is_favorite: false,
      source: source,
      image_src: 'https://example.com/image.jpg'
    }
  end

  let(:test_class) do
    fields = recipe_fields
    Class.new(described_class) do
      fields.each do |field, value|
        define_method("recipe_#{field}") { value }
      end
    end
  end

  describe '#recipe' do
    it 'creates a new Recipe instance' do
      recipe = import.recipe
      expect(recipe).to be_a(Recipe)

      recipe_fields.each do |field, value|
        expect(recipe.send(field)).to eq(value)
      end
    end

    context 'when a getter raises an error' do
      let(:test_class) do
        Class.new(described_class) do
          def recipe_name
            raise StandardError, 'Test error'
          end

          def recipe_yield
            '4 servings'
          end
        end
      end

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'continues setting other fields' do
        import.recipe

        expect(Rails.logger)
          .to have_received(:error)
          .with(/Error setting name in .*: StandardError - Test error. Source: #{source}/)
      end

      it 'does not set the field that raised' do
        expect(import.recipe.name).to be_nil
      end

      it 'sets other fields correctly' do
        expect(import.recipe.yield).to eq('4 servings')
      end
    end
  end
end
