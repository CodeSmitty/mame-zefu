# frozen_string_literal: true

require 'net/http'

class ApplicationController < ActionController::Base
  include Clearance::Controller
  include Pundit::Authorization
  after_action :verify_pundit_authorization, except: %i[health_check]

  def health_check
    render json: { started_at:, updated_at:, ok: healthy? }, status:
  end

  private

  def started_at
    Uptime::STARTED_AT
  end

  def updated_at
    @updated_at ||=
      Rails.cache.fetch(cache_key, skip_nil: true, expires_in: 5.minutes) do
        tag&.dig('last_updated')
      end
  end

  def tag
    return if tag_url.blank?

    uri = URI(tag_url)
    res = Net::HTTP.get_response(uri)
    return unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
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
