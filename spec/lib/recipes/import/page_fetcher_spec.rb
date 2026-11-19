# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Recipes::Import::PageFetcher do
  subject(:fetcher) { described_class.new(URI(url)) }

  let(:url) { 'https://example.com/recipe' }
  let(:html) { '<html><body><h1>Recipe</h1></body></html>' }
  let!(:request) { stub_request(:get, url).to_return(body: html) }

  describe '#document' do
    it 'parses the response as an HTML document' do
      expect(fetcher.document.at_css('h1').text).to eq('Recipe')
    end

    it 'sends a browser-compatible user agent' do
      fetcher.document
      expect(request.with(headers: { 'User-Agent' => described_class::USER_AGENT })).to have_been_requested
    end

    it 'caches the document' do
      2.times { fetcher.document }
      expect(request).to have_been_requested.once
    end

    context 'when the page redirects' do
      let!(:request) { stub_request(:get, url).to_return(status: 302, headers: { 'Location' => '/new-recipe' }) }
      let!(:redirect_request) { stub_request(:get, 'https://example.com/new-recipe').to_return(body: html) }

      it 'fetches the redirected page' do
        expect(fetcher.document.at_css('h1').text).to eq('Recipe')
      end

      it 'sends the user agent on the redirected request' do
        fetcher.document
        expect(redirect_request.with(headers: { 'User-Agent' => described_class::USER_AGENT })).to have_been_requested
      end
    end

    context 'when the page request fails' do
      let!(:request) { stub_request(:get, url).to_return(status: 403) }

      it 'reports the HTTP status' do
        expect { fetcher.document }.to raise_error(Recipes::Import::FetchError, /HTTP 403/)
      end
    end

    context 'when redirects exceed the limit' do
      let!(:request) { stub_request(:get, url).to_return(status: 302, headers: { 'Location' => url }) }

      it 'reports the redirect failure' do
        expect { fetcher.document }.to raise_error(Recipes::Import::FetchError, /HTTP 302/)
      end

      it 'stops after the configured number of redirects' do
        expect { fetcher.document }.to raise_error(Recipes::Import::FetchError)
        expect(request).to have_been_requested.times(described_class::MAX_REDIRECTS + 1)
      end
    end

    context 'when the page redirects five times' do
      let!(:request) { stub_request(:get, url).to_return(status: 302, headers: { 'Location' => '/1' }) }

      before do
        (1..4).each do |index|
          stub_request(:get, "https://example.com/#{index}")
            .to_return(status: 302, headers: { 'Location' => "/#{index + 1}" })
        end
        stub_request(:get, 'https://example.com/5').to_return(body: html)
      end

      it 'fetches the final page' do
        expect(fetcher.document.at_css('h1').text).to eq('Recipe')
      end
    end

    context 'when a redirect has no location' do
      let!(:request) { stub_request(:get, url).to_return(status: 302) }

      it 'reports the redirect failure' do
        expect { fetcher.document }.to raise_error(Recipes::Import::FetchError, /HTTP 302/)
      end
    end
  end
end
