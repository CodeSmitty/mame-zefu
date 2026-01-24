require 'rails_helper'

RSpec.describe 'Health Check' do
  describe 'GET /health_check' do
    let(:tag_url) { 'https://example.com/foo/bar' }
    let(:tag_status) { 200 }
    let(:tag_body) { { last_updated: tag_updated }.to_json }
    let(:tag_headers) { { 'Content-Type' => 'application/json' } }
    let(:tag_updated) { 1.hour.ago.iso8601 }

    before do
      ENV['IMAGE_TAG_URL'] = tag_url

      stub_request(:get, tag_url)
        .to_return(status: tag_status, body: tag_body, headers: tag_headers)
    end

    it 'returns :ok' do
      get health_check_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(ok: true, updated_at: tag_updated)
    end

    context 'when tag updated after app start' do
      let(:tag_updated) { 1.hour.from_now.iso8601 }

      it 'returns :service_unavailable' do
        get health_check_path

        expect(response).to have_http_status(:service_unavailable)
        expect(response.parsed_body).to include(ok: false, updated_at: tag_updated)
      end
    end

    context 'when tag fetch fails' do
      let(:tag_status) { 500 }

      it 'returns :ok' do
        get health_check_path

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(ok: true, updated_at: nil)
      end
    end

    context 'when tag fetch times out' do
      before do
        stub_request(:get, tag_url).to_timeout
      end

      it 'returns :ok' do
        get health_check_path

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(ok: true, updated_at: nil)
      end
    end

    context 'when IMAGE_TAG_URL is not set' do
      before do
        ENV['IMAGE_TAG_URL'] = nil
      end

      it 'returns :ok' do
        get health_check_path

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(ok: true, updated_at: nil)
      end
    end

    context 'when ready check' do
      it 'returns :ok' do
        get health_check_path, params: { q: 'ready' }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
