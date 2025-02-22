require_relative 'endpoint_methods'

# Filters messages to contain only the content (text), user (author_id), and pub_date (pub_date)
def filter_messages(messages, verbose)
  if verbose
    messages.map { |msg| { user: msg['username'], content: msg['text'], timestamp: format_datetime(msg['pub_date']) } }
  else
    messages.map { |msg| { content: msg['text'], user: msg['author_id'], pub_date: msg['pub_date'] } }
  end
end

# Returns the value of a given parameter, or if it hasn't been passed, the default value
def get_param_or_default(param_name, default_value)
  val = default_value
  unless params[param_name].nil?
    val = params[param_name].to_i
  end

  val
end

# API Endpoints

get '/api/latest' do
  return get_latest.to_json
end

post '/api/register' do
  error = register_user(params['username'], params['email'], params['password'], params['password'])
  status = error.nil? ? 'success' : 'error'
  message = error.nil? ? "You were successfully registered and can login now" : error
  { status: status, message: message }.to_json
end

get '/api/msgs' do
  verbose = get_param_or_default('verbose', 0)
  limit = get_param_or_default('no', 100)
  messages = get_messages(limit)
  filter_messages(messages, verbose == 1).to_json
end

get '/api/msgs/:username' do
  verbose = get_param_or_default('verbose', 0)
  user_id = get_user_id(params[:username])
  limit = get_param_or_default('no', 100)
  messages = get_messages(limit, user_id)
  filter_messages(messages, verbose == 1).to_json
end

post '/api/msgs/:username' do
  user_id = get_user_id(params[:username])
  message = params['content']
  post_message(message, user_id)

  status 204
end

get '/api/fllws/:username' do
  limit = get_param_or_default('no', 100)
  followers = get_followers(params[:username], limit)
  { follows: followers }.to_json
end

post '/api/fllws/:username' do
  unless params['follow'].nil?
    follower_id = get_user_id(params[:username])
    follow(follower_id, params['follow'])
    status 204
  end

  unless params['unfollow'].nil?
    follower_id = get_user_id(params[:username])
    unfollow(follower_id, params['unfollow'])
    status 204
  end

  status 400
end