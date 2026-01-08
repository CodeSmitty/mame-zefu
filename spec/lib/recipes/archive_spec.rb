# frozen_string_literal: true

require 'rails_helper'
require 'zip'

RSpec.describe Recipes::Archive do
  subject(:archive) { described_class.new(user) }

  let(:user) { create(:user) }

  def zip_io(recipes_json: nil, images: {}) # rubocop:disable Metrics/MethodLength
    buffer = Zip::OutputStream.write_buffer do |out|
      if recipes_json
        out.put_next_entry('recipes.json')
        out.write JSON.pretty_generate(recipes_json)
      end

      images.each do |filename, content|
        out.put_next_entry("images/#{filename}")
        out.write content
      end
    end

    buffer.rewind
    StringIO.new(buffer.string)
  end

  describe '#generate' do
    subject(:generate) { archive.generate }

    let(:recipe_name) { 'Test Recipe' }
    let(:filename) { 'foo.png' }

    before do
      recipe = create(:recipe, user: user, name: recipe_name)
      recipe.image.attach(io: StringIO.new('IMAGE_DATA'), filename: filename, content_type: 'image/png')
    end

    it 'creates a zip containing recipes.json and attached images' do # rubocop:disable RSpec/ExampleLength
      Zip::File.open(generate) do |zip|
        expect(zip.glob('recipes.json').first).to be_present

        json = JSON.parse(zip.read('recipes.json'))
        expect(json.size).to eq(1)
        expect(json.first['name']).to eq(recipe_name)

        expect(zip.glob("images/#{filename}").first).to be_present
      end
    end
  end

  describe '#restore' do
    subject(:restore) { archive.restore(io) }

    let(:io) { zip_io(recipes_json: recipes_json, images: images) }
    let(:recipes_json) do
      [
        {
          'name' => recipe_name,
          'image' => { 'filename' => recipe_image_name }
        }
      ]
    end
    let(:images) do
      { recipe_image_name => recipe_image_data }
    end
    let(:recipe_name) { 'salad' }
    let(:recipe_image_name) { 'salad.png' }
    let(:recipe_image_data) { 'PNGDATA' }

    context 'with a valid archive' do
      it 'imports recipes and attached images' do
        expect(restore).to eq({ created: 1, skipped: 0 })

        recipe = user.recipes.find_by(name: recipe_name)
        expect(recipe).to be_present
        expect(recipe.image).to be_attached
      end

      it 'skips recipes that already exist for the user' do
        create(:recipe, user: user, name: recipes_json.first['name'])

        expect(restore).to eq({ created: 0, skipped: 1 })
      end
    end

    context 'when recipes.json is missing' do
      let(:recipes_json) { nil }

      it 'raises RecipeFileMissingError' do
        expect { restore }.to raise_error(Recipes::Archive::RecipeFileMissingError)
      end
    end

    context 'when image referenced in recipes.json is missing' do
      let(:images) { {} }

      it 'raises RecipeImageMissingError' do
        expect { restore }.to raise_error(Recipes::Archive::RecipeImageMissingError)
      end
    end

    context 'when an image exceeds the maximum allowed size' do
      let(:recipe_image_data) { 'a' * (Recipe::MAX_IMAGE_SIZE + 1) }

      it 'raises RecipeImageTooLargeError' do
        expect { restore }.to raise_error(Recipes::Archive::RecipeImageTooLargeError)
      end
    end
  end
end
