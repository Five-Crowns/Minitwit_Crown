require 'prometheus/client'

module Metrics
  PROMETHEUS = Prometheus::Client.registry

  def self.http_requests_total
    @http_requests_total ||= Prometheus::Client::Counter.new(
      :http_requests_total,
      docstring: 'Total number of HTTP requests received',
      labels: [:method, :route, :status]
    )
  end

  def self.http_request_duration_seconds
    @http_request_duration_seconds ||= Prometheus::Client::Histogram.new(
      :http_request_duration_seconds,
      docstring: 'Histogram for tracking request duration',
      labels: [:method, :route, :status]
    )
  end

  def self.active_users
    @active_users ||= Prometheus::Client::Gauge.new(
      :active_users,
      docstring: 'Currently active users'
    )
  end

  # Register all metrics with Prometheus
  PROMETHEUS.register(http_requests_total)
  PROMETHEUS.register(http_request_duration_seconds)
  PROMETHEUS.register(active_users)
  
end
