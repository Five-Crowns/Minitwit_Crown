require "prometheus/client"

module Metrics
  PROMETHEUS = Prometheus::Client.registry

  def self.http_requests_total
    @http_requests_total ||= Prometheus::Client::Counter.new(
      :http_requests_total,
      docstring: "Total number of HTTP requests received",
      labels: [:method, :route, :status]
    )
  end

  def self.http_request_duration_seconds
    @http_request_duration_seconds ||= Prometheus::Client::Histogram.new(
      :http_request_duration_seconds,
      docstring: "Histogram for tracking request duration",
      labels: [:method, :route, :status]
    )
  end

  def self.active_users
    @active_users ||= Prometheus::Client::Gauge.new(
      :active_users,
      docstring: "Currently active users"
    )
  end

  def self.db_create_msg_duration
    @db_create_msg_duration ||= Prometheus::Client::Histogram.new(
      :db_create_msg_duration,
      docstring: "Database query time for creating a new message",
      labels: [:endpoint]
    )
  end

  def self.db_get_msgs_duration
    @db_get_msgs_duration ||= Prometheus::Client::Histogram.new(
      :db_get_msgs_duration,
      docstring: "Database query time for get_messages",
      labels: [:endpoint]
    )
  end

  def self.db_get_msgs_by_user_duration
    @db_get_msgs_by_user_duration ||= Prometheus::Client::Histogram.new(
      :db_get_msgs_by_user_duration,
      docstring: "Database query time for get_messages for single user",
      labels: [:endpoint]
    )
  end

  def self.db_get_followers_by_user_duration
    @db_get__by_followersuser_duration ||= Prometheus::Client::Histogram.new(
      :db_get_followers_by_user_duration,
      docstring: "Database query time for get_followers for single user",
      labels: [:endpoint]
    )
  end

  def self.db_follow_user_duration
    @db_follow_user_duration ||= Prometheus::Client::Histogram.new(
      :db_follow_user_duration,
      docstring: "Database query time for following a user",
      labels: [:endpoint]
    )
  end

  def self.db_unfollow_user_duration
    @db_unfollow_user_duration ||= Prometheus::Client::Histogram.new(
      :db_unfollow_user_duration,
      docstring: "Database query time for unfollowing a user",
      labels: [:endpoint]
    )
  end

  def self.db_register_user_duration
    @db_register_user_duration ||= Prometheus::Client::Histogram.new(
      :db_register_user_duration,
      docstring: "Database query time for registering a new user",
      labels: [:endpoint]
    )
  end

  # Register all metrics with Prometheus
  PROMETHEUS.register(http_requests_total)
  PROMETHEUS.register(http_request_duration_seconds)
  PROMETHEUS.register(active_users)
  PROMETHEUS.register(db_create_msg_duration)
  PROMETHEUS.register(db_get_msgs_duration)
  PROMETHEUS.register(db_get_msgs_by_user_duration)
  PROMETHEUS.register(db_get_followers_by_user_duration)
  PROMETHEUS.register(db_follow_user_duration)
  PROMETHEUS.register(db_unfollow_user_duration)
  PROMETHEUS.register(db_register_user_duration)
end
