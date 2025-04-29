require_relative "endpoint_methods"
require_relative "../metrics"

SINATRA_ROUTE = "sinatra.route"

# Filters messages to contain only necessary information, that being user (username), content (text), and timestamp (pub_date).
# @param messages The list of messages to filter.
def filter_messages(messages)
  messages.map { |msg| {user: msg["username"], content: msg["text"], timestamp: format_datetime(msg["pub_date"])} }
end

# API Endpoints

before do
  env[SINATRA_ROUTE] = nil
end

get "/api/latest" do
  log_event('Got latest request')
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
    log_event("Successfully registered user #{@data["username"]}")
    status 204
  else
    log_event("Registering user #{@data["username"]} failed with #{error}")
    halt 400, {status: 400, error_msg: error}.to_json
  end
end

get "/api/msgs" do
  log_event("Getting all message")
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
  log_event("Getting messages for user #{params[:username]}")
  env[SINATRA_ROUTE] = "/api/msgs/:username"
  user_id = get_user_id(params[:username])
  limit = get_param_or_default("no", 100)
  start_time = Time.now
  messages = get_messages(limit, user_id)
  duration = Time.now - start_time
  Metrics.db_get_msgs_by_user_duration.observe(
    duration,
    labels: {endpoint: "/api/msgs"}
  )
  filter_messages(messages).to_json
end

post "/api/msgs/:username" do
  env[SINATRA_ROUTE] = "/api/msgs/:username"
  user_id = get_user_id(params[:username])
  message = @data["content"]
  start_time = Time.now
  error = post_message(message, user_id)
  duration = Time.now - start_time
  Metrics.db_create_msg_duration.observe(
    duration,
    labels: {endpoint: "/api/msgs"}
  )
  if error.nil?
    log_event("Successfully posted a message on behalf of user #{params[:username]}")
    status 204
  else
    log_event("Failed to post a message on behalf of user #{params[:username]} with #{error}")
    halt 400, error
  end
end

get "/api/fllws/:username" do
  env[SINATRA_ROUTE] = "/api/fllws/:username"
  limit = get_param_or_default("no", 100)
  start_time = Time.now
  follows = get_follows(params[:username], limit)
  duration = Time.now - start_time
  Metrics.db_get_followers_by_user_duration.observe(
    duration,
    labels: {endpoint: "/api/fllws"}
  )
  usernames = follows.map { |f| f["username"] }
  return {follows: usernames}.to_json
end

post "/api/fllws/:username" do
  env[SINATRA_ROUTE] = "/api/fllws/:username"
  follow = @data["follow"].to_s
  unless follow.empty?
    follower_id = get_user_id(params[:username])
    start_time = Time.now
    error = follow(follower_id, follow)
    duration = Time.now - start_time
    Metrics.db_follow_user_duration.observe(
      duration,
      labels: {endpoint: "/api/fllws"}
    )
    if error.nil?
      log_event("Successfully followed user #{follow}")
      return status 204
    else
      log_event("Failed to follow user #{follow} with error #{error}")
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
      labels: {endpoint: "/api/fllws"}
    )
    if error.nil?
      log_event("Successfully unfollowed user #{unfollow}")
      return status 204
    else
      log_event("Failed to unfollow user #{unfollow} with error #{error}")
      return halt 400, error
    end
  end

  halt 400, "No follow command specified"
end
