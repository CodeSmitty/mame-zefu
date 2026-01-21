require 'rails_helper'

RSpec.describe 'RecipesHelper' do
  let(:user) { create(:user) }
  let(:uploaded_image) { fixture_file_upload('test.png', 'image/png') }
  let!(:recipe) { create(:recipe, user: user, image: uploaded_image) }

  describe '#delete_image_url' do
    context 'when recipe image is persisted' do
      before do
        image = instance_double(ActiveStorage::Attachment, persisted?: true)
        allow(recipe).to receive(:image).and_return(image)
        allow(helper).to receive(:image_recipe_path).with(recipe).and_return('/recipes/1/image')
      end

      it 'returns the image deletion path' do
        expect(helper.delete_image_url(recipe)).to eq('/recipes/1/image')
      end
    end

    context 'when recipe image is not persisted' do
      before do
        image = instance_double(ActiveStorage::Attachment, persisted?: false)
        allow(recipe).to receive(:image).and_return(image)
      end

      it 'returns nil' do
        expect(helper.delete_image_url(recipe)).to be_nil
      end
    end
  end

  describe '#preview_image_src' do
    context 'when recipe has image_src' do
      it 'returns the image source' do
        expect(helper.preview_image_src(recipe)).to eq(recipe.image_src)
      end
    end

    context 'when recipe image is attached but not persisted' do
      let(:recipe) { build(:recipe, user: user) }

      before do
        image = double(uploaded_image, attached?: true, persisted?: false, blob: nil) # rubocop:disable RSpec/VerifiedDoubles
        allow(recipe).to receive_messages(image_src: nil, image: image)
        allow(helper).to receive(:url_for).with(image).and_return(url_for('./test.png'))
      end

      it 'returns the attached image URL' do
        expect(helper.preview_image_src(recipe)).to eq(url_for('./test.png'))
      end
    end
  end

  describe '#default_image_src' do
    it 'returns the path to the default camera image' do
      expect(helper.default_image_src).to eq(helper.asset_path('camera.png'))
    end
  end
end
