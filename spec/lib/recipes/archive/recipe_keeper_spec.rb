# frozen_string_literal: true

require 'rails_helper'
require 'zip'

RSpec.describe Recipes::Archive::RecipeKeeper do
  subject(:archive) { described_class.new(user) }

  let(:user) { create(:user) }

  def zip_io(recipes_html: nil, images: {}) # rubocop:disable Metrics/MethodLength
    buffer = Zip::OutputStream.write_buffer do |out|
      if recipes_html
        out.put_next_entry('recipes.html')
        out.write recipes_html
      end

      images.each do |filename, content|
        out.put_next_entry(filename)
        out.write content
      end
    end

    buffer.rewind
    StringIO.new(buffer.string)
  end

  describe '#generate' do
    it 'raises NotImplementedError' do
      expect { archive.generate }.to raise_error(NotImplementedError)
    end
  end

  describe '#restore' do
    subject(:restore) { archive.restore(io) }

    let(:io) { zip_io(recipes_html: recipes_html, images: images) }
    let(:recipes_html) do
      <<~HTML
        <html>
          <body>
            <div class="recipe-details">
              <table>
                <tr>
                  <td style="vertical-align:top">
                    <h2 itemprop="name">#{recipe_name}</h2>
                  </td>
                </tr>
              </table>
              <div class="recipe-photos-div"><img src="#{recipe_image_src}" class="recipe-photos" itemprop=photo0 /></div>
            </div>
          </body>
        </html>
      HTML
    end
    let(:images) do
      { recipe_image_src => recipe_image_data }
    end
    let(:recipe_name) { 'My Cake' }
    let(:recipe_image_src) { 'images/cake.png' }
    let(:recipe_image_data) { 'IMAGE_DATA' }

    context 'with a valid archive' do
      it 'imports recipes and attached images' do
        expect(restore).to eq({ created: 1, skipped: 0 })

        recipe = user.recipes.find_by(name: recipe_name)
        expect(recipe).to be_present
        expect(recipe.image).to be_attached
      end

      it 'skips recipes that already exist' do
        create(:recipe, user: user, name: recipe_name)

        expect(restore).to eq({ created: 0, skipped: 1 })
      end
    end

    context 'when recipes.html is missing' do
      let(:recipes_html) { nil }

      it 'raises RecipeFileMissingError' do
        expect { restore }.to raise_error(Recipes::Archive::RecipeFileMissingError)
      end
    end

    context 'when images are missing' do
      let(:images) { {} }

      it 'raises RecipeImageMissingError' do
        expect { restore }.to raise_error(Recipes::Archive::RecipeImageMissingError)
      end
    end

    context 'when an image exceeds the maximum allowed size' do
      let(:images) do
        { recipe_image_src => 'a' * (Recipe::MAX_IMAGE_SIZE + 1) }
      end

      it 'raises RecipeImageTooLargeError' do
        expect { restore }.to raise_error(Recipes::Archive::RecipeImageTooLargeError)
      end
    end
  end
end
