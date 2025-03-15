require_relative 'endpoint_methods'

# Filters messages to contain only necessary information, that being user (username), content (text), and timestamp (pub_date).
# @param messages The list of messages to filter.
def filter_messages(messages)
  messages.map { |msg| { user: msg['username'], content: msg['text'], timestamp: format_datetime(msg['pub_date']) } }
end

# API Endpoints

get '/api/latest' do
  latest = get_latest.to_i
  return { latest: latest }.to_json
end

post '/api/register' do
  error = register_user(@data['username'], @data['email'], @data['pwd'], @data['pwd'])
  if error.nil?
    status 204
  else
    halt 400, { status: 400, error_msg: error }.to_json
  end
end

get '/api/msgs' do
  limit = get_param_or_default('no', 100)
  messages = get_messages(limit)
  filter_messages(messages).to_json
end

get '/api/msgs/:username' do
  user_id = get_user_id(params[:username])
  limit = get_param_or_default('no', 100)
  messages = get_messages(limit, user_id)
  filter_messages(messages).to_json
end

post '/api/msgs/:username' do
  user_id = get_user_id(params[:username])
  message = @data['content']
  error = post_message(message, user_id)
  if error.nil?
    status 204
  else
    halt 400, error
  end
end

get '/api/fllws/:username' do
  limit = get_param_or_default('no', 100)
  followers = get_followers(params[:username], limit)
  usernames = followers.map { |f| f['username'] }
  return { follows: usernames }.to_json
end

post '/api/fllws/:username' do
  follow = @data['follow'].to_s
  unless follow.empty?
    follower_id = get_user_id(params[:username])
    error = follow(follower_id, follow)
    if error.nil?
      return status 204
    else
      return halt 400, error
    end
  end

  unfollow = @data['unfollow'].to_s
  unless unfollow.empty?
    follower_id = get_user_id(params[:username])
    error = unfollow(follower_id, unfollow)
    if error.nil?
      return status 204
    else
      return halt 400, error
    end
  end

  halt 400, 'No follow command specified'
end