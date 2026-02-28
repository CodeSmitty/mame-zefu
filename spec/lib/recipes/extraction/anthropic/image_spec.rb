# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Extraction::Anthropic::Image do
  let(:uploaded_image) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test.png'), 'image/png') }
  let(:service) { described_class.new(image: uploaded_image) }

  describe '#source' do
    it 'always normalizes image bytes before returning source payload' do # rubocop:disable RSpec/ExampleLength
      normalized = instance_double(MiniMagick::Image, to_blob: 'normalized-bytes', type: 'PNG', destroy!: true)
      allow(service).to receive(:ensure_imagemagick_available!)
      allow(service).to receive(:source_image_bytes).and_return('raw-bytes')
      allow(service).to receive(:normalized_image).with('raw-bytes').and_return(normalized)
      allow(service).to receive(:payload_within_limit?).with('normalized-bytes').and_return(true)
      allow(service).to receive(:downsampled_jpeg_bytes)

      result = service.source

      expect(result[:media_type]).to eq('image/png')
      expect(Base64.decode64(result[:data])).to eq('normalized-bytes')
      expect(service).not_to have_received(:downsampled_jpeg_bytes)
    end

    it 'falls back to jpeg downsampling when normalized payload is still too large' do # rubocop:disable RSpec/ExampleLength
      normalized = instance_double(MiniMagick::Image, to_blob: 'normalized-bytes', type: 'PNG', destroy!: true)
      allow(service).to receive(:ensure_imagemagick_available!)
      allow(service).to receive_messages(
        source_image_bytes: 'raw-bytes',
        normalized_image: normalized
      )
      allow(service).to receive(:payload_within_limit?).with('normalized-bytes').and_return(false)
      allow(service).to receive(:downsampled_jpeg_bytes).with(normalized).and_return('jpeg-bytes')

      result = service.source

      expect(result[:media_type]).to eq('image/jpeg')
      expect(Base64.decode64(result[:data])).to eq('jpeg-bytes')
    end

    xit 'raises when imagemagick tooling is unavailable' do
      allow(service).to receive(:ensure_imagemagick_available!).and_raise(
        Recipes::Extraction::Anthropic::Image::Error,
        'Image preprocessing requires ImageMagick CLI tools. Install imagemagick or upload a smaller image.'
      )

      expect { service.source }.to raise_error(Recipes::Extraction::Anthropic::Image::Error, /ImageMagick CLI tools/)
    end
  end

  describe '#downsampled_jpeg_bytes' do
    it 'uses binary quality search to find a fitting jpeg' do # rubocop:disable RSpec/ExampleLength
      image = instance_double(MiniMagick::Image)
      allow(image).to receive_messages(width: 1000, height: 800, to_blob: 'x' * (6 * 1024 * 1024))

      candidate = instance_double(MiniMagick::Image)
      allow(candidate).to receive(:destroy!)
      allow(image).to receive(:clone).and_return(candidate)
      allow(service).to receive(:resize_to)

      allow(service).to receive(:encode_jpeg) do |_img, quality:|
        quality <= 80 ? 'fit' : 'too-big'
      end
      allow(service).to receive(:payload_within_limit?) { |bytes| bytes == 'fit' }

      result = service.send(:downsampled_jpeg_bytes, image)

      expect(result).to eq('fit')
      expect(service).to have_received(:encode_jpeg).at_least(:twice)
    end

    it 'raises when no resize/quality combination fits under limit' do # rubocop:disable RSpec/ExampleLength
      image = instance_double(MiniMagick::Image)
      allow(image).to receive_messages(width: 1000, height: 800, to_blob: 'x' * (8 * 1024 * 1024))

      candidate = instance_double(MiniMagick::Image)
      allow(candidate).to receive(:destroy!)
      allow(image).to receive(:clone).and_return(candidate)
      allow(service).to receive(:resize_to)
      allow(service).to receive_messages(
        encode_jpeg: 'always-too-big',
        payload_within_limit?: false
      )

      expect do
        service.send(:downsampled_jpeg_bytes, image)
      end.to raise_error(Recipes::Extraction::Anthropic::Image::Error, /could not be reduced/)
    end
  end
end
