class ApplicationController < ActionController::Base
  def health_check
    render json: { ttl:, uptime:, ok: healthy? }, status:
  end

  private

  def ttl
    Uptime::TTL
  end

  def uptime
    Time.current - Uptime::BOOTED_AT
  end

  def healthy?
    uptime < ttl
  end

  def status
    healthy? ? :ok : :service_unavailable
  end
end
