require_relative 'endpoint_methods'

# Filters messages to contain only necessary information
# @param messages The list of messages to filter.
# @param [Integer] verbose Changes if messages are filtered for the simulator (0), or for human readability (1).
def filter_messages(messages, verbose)
  if verbose == 1
    messages.map { |msg| { user: msg['username'], content: msg['text'], timestamp: format_datetime(msg['pub_date']) } }
  else
    messages.map { |msg| { content: msg['text'], user: msg['author_id'], pub_date: msg['pub_date'] } }
  end
end

# API Endpoints

get '/api/latest' do
  return get_latest.to_json
end

post '/api/register' do
  error = register_user(params['username'], params['email'], params['password'], params['password'])
  if error.nil?
    status 200, 'You were successfully registered and can login now'
  else
    halt 400, error
  end
end

get '/api/msgs' do
  verbose = get_param_or_default('verbose', 0)
  limit = get_param_or_default('no', 100)
  messages = get_messages(limit)
  filter_messages(messages, verbose).to_json
end

get '/api/msgs/:username' do
  verbose = get_param_or_default('verbose', 0)
  user_id = get_user_id(params[:username])
  limit = get_param_or_default('no', 100)
  messages = get_messages(limit, user_id)
  filter_messages(messages, verbose).to_json
end

post '/api/msgs/:username' do
  user_id = get_user_id(params[:username])
  message = params['content']
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
  { follows: followers }.to_json
end

post '/api/fllws/:username' do
  follow = params['follow'].to_s
  unless follow.empty?
    follower_id = get_user_id(params[:username])
    error = follow(follower_id, follow)
    if error.nil?
      return status 204
    else
      return halt 400, error
    end
  end

  unfollow = params['unfollow'].to_s
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