require_relative "endpoint_methods"
require_relative "../metrics"

# Filters messages to contain only necessary information, that being user (username), content (text), and timestamp (pub_date).
# @param messages The list of messages to filter.
def filter_messages(messages)
  messages.map { |msg| {user: msg["username"], content: msg["text"], timestamp: format_datetime(msg["pub_date"])} }
end

# API Endpoints

get "/api/latest" do
  latest = get_latest.to_i
  return {latest: latest}.to_json
end

post "/api/register" do
  start_time = Time.now
  error = register_user(@data["username"], @data["email"], @data["pwd"], @data["pwd"])
  duration = Time.now - start_time
  Metrics.db_register_user_duration.observe(
    duration,
    labels: {endpoint: "/api/register"}
  )
  if error.nil?
    status 204
  else
    halt 400, {status: 400, error_msg: error}.to_json
  end
end

get "/api/msgs" do
  limit = get_param_or_default("no", 100)
  start_time = Time.now
  messages = get_messages(limit)
  duration = Time.now - start_time
  Metrics.db_get_msgs_duration.observe(
    duration,
    labels: {endpoint: "/api/msgs"}
  )
  filter_messages(messages).to_json
end

get "/api/msgs/:username" do
  user_id = get_user_id(params[:username])
  limit = get_param_or_default("no", 100)
  start_time = Time.now
  messages = get_messages(limit, user_id)
  duration = Time.now - start_time
  Metrics.db_get_msgs_by_user_duration.observe(
    duration,
    labels: {endpoint: "/api/msgs/:username"}
  )
  filter_messages(messages).to_json
end

post "/api/msgs/:username" do
  user_id = get_user_id(params[:username])
  message = @data["content"]
  start_time = Time.now
  error = post_message(message, user_id)
  duration = Time.now - start_time
  Metrics.db_create_msg_duration.observe(
    duration,
    labels: {endpoint: "/api/msgs/:username"}
  )
  if error.nil?
    status 204
  else
    halt 400, error
  end
end

get "/api/fllws/:username" do
  limit = get_param_or_default("no", 100)
  start_time = Time.now
  followers = get_followers(params[:username], limit)
  duration = Time.now - start_time
  Metrics.db_get_followers_by_user_duration.observe(
    duration,
    labels: {endpoint: "/api/fllws/:username"}
  )
  usernames = followers.map { |f| f["username"] }
  return {follows: usernames}.to_json
end

post "/api/fllws/:username" do
  follow = @data["follow"].to_s
  unless follow.empty?
    follower_id = get_user_id(params[:username])
    start_time = Time.now
    error = follow(follower_id, follow)
    duration = Time.now - start_time
    Metrics.db_follow_user_duration.observe(
      duration,
      labels: {endpoint: "/api/fllws/:username"}
    )
    if error.nil?
      return status 204
    else
      return halt 400, error
    end
  end

  unfollow = @data["unfollow"].to_s
  unless unfollow.empty?
    follower_id = get_user_id(params[:username])
    start_time = Time.now
    error = unfollow(follower_id, unfollow)
    duration = Time.now - start_time
    Metrics.db_unfollow_user_duration.observe(
      duration,
      labels: {endpoint: "/api/fllws/:username"}
    )
    if error.nil?
      return status 204
    else
      return halt 400, error
    end
  end

  halt 400, "No follow command specified"
end
