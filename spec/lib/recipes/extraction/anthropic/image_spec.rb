# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Extraction::Anthropic::Image do
  let(:image_file) { Rails.root.join('spec/fixtures/files/test.png').to_s }
  let(:media_type) { 'image/png' }
  let(:image) { instance_double(MiniMagick::Image) }
  let(:service) { described_class.new(image_file:, media_type:) }

  before do
    allow(MiniMagick::Utilities).to receive(:which).and_return('/usr/bin/convert')
    allow(MiniMagick::Image).to receive(:open).and_return(image)
    allow(MiniMagick::Image).to receive(:open).with(image_file).and_return(image)
  end

  describe '#source' do
    before do
      allow(service).to receive(:normalize_image)
    end

    context 'when normalized image already fits limit' do
      let(:normalized_bytes) { 'normalized-bytes' }

      before do
        allow(image).to receive(:to_blob).and_return(normalized_bytes)
        allow(service).to receive(:within_size_limit?).with(image).and_return(true)
        allow(service).to receive(:downsample_image)
      end

      it 'returns original media type' do
        result = service.source

        expect(result[:media_type]).to eq('image/png')
      end

      it 'returns normalized payload bytes' do
        result = service.source

        expect(Base64.decode64(result[:data])).to eq(normalized_bytes)
      end

      it 'does not downsample image' do
        service.source

        expect(service).not_to have_received(:downsample_image)
      end
    end

    context 'when downsampling runs' do
      let(:downsampled) { instance_double(MiniMagick::Image, to_blob: 'jpeg-bytes') }

      before do
        allow(service).to receive(:within_size_limit?).with(image).and_return(false)
        allow(service).to receive(:downsample_image) do
          service.instance_variable_set(:@image, downsampled)
          service.instance_variable_set(:@media_type, 'image/jpeg')
        end
      end

      it 'returns jpeg media type' do
        result = service.source

        expect(result[:media_type]).to eq('image/jpeg')
      end

      it 'returns downsampled payload bytes' do
        result = service.source

        expect(Base64.decode64(result[:data])).to eq('jpeg-bytes')
      end
    end

    it 'wraps MiniMagick processing errors' do
      allow(service).to receive(:normalize_image).and_raise(MiniMagick::Error, 'bad image')

      expect { service.source }.to raise_error(described_class::Error, /Image preprocessing failed: bad image/)
    end

    it 'raises when imagemagick tooling is unavailable' do
      allow(MiniMagick::Utilities).to receive(:which).and_return(nil)

      expect do
        described_class.new(image_file:, media_type:)
      end.to raise_error(described_class::Error, /ImageMagick CLI tools/)
    end
  end

  describe 'private helpers' do
    describe '#normalize_image' do
      let(:mutable_image) { double('MiniMagickImage') } # rubocop:disable RSpec/VerifiedDoubles
      let(:builder) { double('MiniMagickBuilder') } # rubocop:disable RSpec/VerifiedDoubles

      before do
        service.instance_variable_set(:@image, mutable_image)
        allow(mutable_image).to receive(:auto_orient)
        allow(mutable_image).to receive(:combine_options).and_yield(builder)
        allow(builder).to receive_messages(colorspace: nil, background: nil, alpha: nil, flatten: nil, strip: nil)

        service.send(:normalize_image)
      end

      it 'auto-orients the image' do
        expect(mutable_image).to have_received(:auto_orient)
      end

      it 'sets sRGB colorspace' do
        expect(builder).to have_received(:colorspace).with('sRGB')
      end

      it 'sets white background' do
        expect(builder).to have_received(:background).with('white')
      end

      it 'removes alpha channel' do
        expect(builder).to have_received(:alpha).with('remove')
      end

      it 'flattens image layers' do
        expect(builder).to have_received(:flatten)
      end

      it 'strips metadata' do
        expect(builder).to have_received(:strip)
      end
    end

    describe 'size and dimension helpers' do
      let(:bytes) { 'x' * (described_class::MAX_BASE64_BYTES * 3 / 4) }

      before do
        allow(image).to receive(:to_blob).and_return(bytes)
        allow(image).to receive_messages(width: 1000, height: 800)
      end

      it 'checks base64 payload limit' do
        expect(service.send(:within_size_limit?, image)).to be(true)
      end

      it 'computes resized dimensions' do
        expect(service.send(:resize_dimension, 10, 0.5)).to eq(5)
      end

      it 'formats dimensions for logs' do
        expect(service.send(:image_dimensions, image)).to eq('1000x800')
      end

      it 'formats image size for logs' do
        expect(service.send(:image_size, image)).to end_with('MB')
      end
    end

    describe '#open_copy' do
      it 'builds an isolated image copy from file path' do
        allow(image).to receive(:path).and_return('/tmp/source.png')
        copy = instance_double(MiniMagick::Image)
        allow(MiniMagick::Image).to receive(:open).with('/tmp/source.png').and_return(copy)

        expect(service.send(:open_copy, image)).to eq(copy)
      end
    end

    describe '#initial_resize_target' do
      it 'calculates target dimensions from current image bytes' do
        allow(image).to receive_messages(to_blob: 'x' * (4 * 1024 * 1024), width: 3000, height: 2000)

        width, height = service.send(:initial_resize_target)

        expect(width).to be < 3000
        expect(height).to be < 2000
      end
    end

    describe '#downsample_jpeg' do
      let(:builder) { double('MiniMagickBuilder') } # rubocop:disable RSpec/VerifiedDoubles
      let(:jpeg) { double('MiniMagickImage') } # rubocop:disable RSpec/VerifiedDoubles

      before do
        allow(jpeg).to receive(:combine_options).and_yield(builder)
        allow(builder).to receive_messages(quality: nil, strip: nil)

        service.send(:downsample_jpeg, jpeg, quality: 92)
      end

      it 'applies provided quality' do
        expect(builder).to have_received(:quality).with('92')
      end

      it 'strips metadata' do
        expect(builder).to have_received(:strip)
      end
    end

    describe '#log_downsample' do
      let(:logger) { instance_double(Logger, info: nil) }

      before do
        allow(Rails).to receive(:logger).and_return(logger)
        input = instance_double(MiniMagick::Image, width: 1200, height: 800, to_blob: 'x' * 1024)
        output = instance_double(MiniMagick::Image, width: 900, height: 600, to_blob: 'x' * 512)
        service.instance_variable_set(:@image, input)

        service.send(:log_downsample, resize_count: 1, jpeg: output, quality: 90)
      end

      it 'logs resize count metadata' do
        expect(logger).to have_received(:info).with(include('Image downsample: resize_count=1'))
      end
    end
  end

  describe '#downsample_image' do
    context 'when best-fit jpeg is found' do
      let(:candidate) { double('MiniMagickImage', resize: nil, destroy!: nil) } # rubocop:disable RSpec/VerifiedDoubles

      before do
        allow(service).to receive(:initial_resize_target).and_return([500, 400])
        allow(service).to receive(:open_copy).with(image).and_return(candidate)
        allow(service).to receive(:best_fit_jpeg).with(candidate).and_return([candidate, 90])
        allow(service).to receive(:log_downsample)

        service.send(:downsample_image)
      end

      it 'stores successful candidate as image' do
        expect(service.send(:image)).to eq(candidate)
      end

      it 'does not destroy selected candidate' do
        expect(candidate).not_to have_received(:destroy!)
      end
    end

    context 'when no quality fits after all resize attempts' do
      let(:candidates) do
        Array.new(3) { double('MiniMagickImage', resize: nil, destroy!: nil) } # rubocop:disable RSpec/VerifiedDoubles
      end

      before do
        allow(service).to receive_messages(initial_resize_target: [500, 400], best_fit_jpeg: [nil, nil])
        allow(service).to receive(:open_copy).with(image).and_return(*candidates)
        allow(service).to receive(:log_downsample)
      end

      it 'raises a payload limit error' do
        expect { service.send(:downsample_image) }.to raise_error(described_class::Error, /payload limit/)
      end

      it 'destroys all failed candidates' do
        attempt_downsample(service)

        expect(candidates).to all(have_received(:destroy!))
      end
    end
  end

  describe '#best_fit_jpeg' do
    let(:probe) { instance_double(MiniMagick::Image) }

    context 'when one quality candidate fits' do
      let(:jpeg) { instance_double(MiniMagick::Image, type: 'PNG', format: nil, destroy!: nil) }
      let(:first_try) { instance_double(MiniMagick::Image, destroy!: nil) }
      let(:second_try) { instance_double(MiniMagick::Image, destroy!: nil) }
      let(:third_try) { instance_double(MiniMagick::Image, destroy!: nil) }

      before do
        allow(service).to receive(:open_copy).with(probe).and_return(jpeg)
        allow(service).to receive(:open_copy).with(jpeg).and_return(first_try, second_try, third_try)
        allow(service).to receive(:downsample_jpeg) { |candidate, **_kwargs| candidate }
        allow(service).to receive(:within_size_limit?) { |candidate| candidate.equal?(third_try) }
      end

      it 'returns first fitting candidate and quality' do
        result = service.send(:best_fit_jpeg, probe)

        expect(result).to eq([third_try, 90])
      end

      it 'converts base copy to jpeg once' do
        service.send(:best_fit_jpeg, probe)

        expect(jpeg).to have_received(:format).with('jpg')
      end

      it 'destroys failed attempts and base copy' do
        service.send(:best_fit_jpeg, probe)

        expect(first_try).to have_received(:destroy!)
        expect(second_try).to have_received(:destroy!)
        expect(jpeg).to have_received(:destroy!)
      end
    end

    context 'when no quality candidate fits' do
      let(:jpeg) { instance_double(MiniMagick::Image, type: 'JPEG', format: nil, destroy!: nil) }
      let(:tries) { Array.new(5) { instance_double(MiniMagick::Image, destroy!: nil) } }
      let(:result) { service.send(:best_fit_jpeg, probe) }

      before do
        allow(service).to receive(:open_copy).with(probe).and_return(jpeg)
        allow(service).to receive(:open_copy).with(jpeg).and_return(*tries)
        allow(service).to receive(:downsample_jpeg) { |candidate, **_kwargs| candidate }
        allow(service).to receive(:within_size_limit?).and_return(false)
        result
      end

      it 'returns nil tuple' do
        expect(result).to eq([nil, nil])
      end

      it 'does not reconvert jpeg images' do
        expect(jpeg).not_to have_received(:format)
      end

      it 'destroys all failed attempts' do
        expect(tries).to all(have_received(:destroy!))
      end

      it 'destroys base copy' do
        expect(jpeg).to have_received(:destroy!)
      end
    end
  end

  def attempt_downsample(service)
    service.send(:downsample_image)
  rescue described_class::Error
    nil
  end
end
