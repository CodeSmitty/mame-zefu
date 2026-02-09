# frozen_string_literal: true

require 'net/http'

class ApplicationController < ActionController::Base
  rescue_from ActionController::RoutingError, with: :not_found
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  include Clearance::Controller
  include Pundit::Authorization

  after_action :verify_pundit_authorization, except: %i[health_check not_found]

  TAG_TIMEOUT = 5

  def health_check
    params[:q] == 'ready' ? ready_response : live_response
  end

  def not_found
    render file: Rails.root.join(Rails.public_path, '404.html'), status: :not_found, layout: false
  end

  private

  def ready_response
    head :ok
  end

  def live_response
    render json: { started_at:, updated_at:, ok: healthy? }, status:
  end

  def started_at
    Uptime::STARTED_AT
  end

  def updated_at
    @updated_at ||=
      Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        tag&.dig('last_updated')
      end
  end

  def tag
    return if tag_url.blank?

    uri = URI(tag_url)
    res = get_tag(uri)
    return if res.blank?

    unless res.is_a?(Net::HTTPSuccess)
      Rails.logger.error("Health check: failed to fetch tag from #{uri} with status #{res.code}")
      return
    end

    JSON.parse(res.body)
  end

  def get_tag(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: TAG_TIMEOUT) do |http|
      req = Net::HTTP::Get.new(uri)
      http.request(req)
    end
  rescue Net::ReadTimeout, Net::OpenTimeout
    Rails.logger.warn("Health check: timed out fetching tag from #{uri}")

    nil
  end

  def tag_url
    ENV.fetch('IMAGE_TAG_URL', nil)
  end

  def healthy?
    updated_at.blank? || Time.zone.parse(updated_at) < started_at
  end

  def status
    healthy? ? :ok : :service_unavailable
  end

  def cache_key
    'health_check:image_updated'
  end

  def verify_pundit_authorization
    if action_name == 'index'
      verify_policy_scoped
    else
      verify_authorized
    end
  end
end
