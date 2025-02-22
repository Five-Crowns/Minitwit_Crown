require_relative 'endpoint_methods'

# Formatter for API responses
def api_response(error, success_message)
  status = error.nil? ? 'success' : 'error'
  message = error.nil? ? success_message : error
  { status: status, message: message }.to_json
end

def filter_messages(messages)
  messages.map { |msg| { content: msg['text'], user: msg['author_id'], pub_date: msg['pub_date'] } }
end

def get_param_or_default(param_name, default_value)
  val = default_value
  unless params[param_name].nil?
    val = params[param_name].to_i
  end

  val
end

get '/api/latest' do
  return get_latest.to_json
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
  post_message(params['content'], user_id)
  status 204
end

get '/api/fllws/:username' do
  getFollowers(params[:username], params[:no].to_i)
  filtered_followers = followers.map { |msg| {username: msg['text'], follows: msg['author_id']}}
  filtered_followers.to_json
end

post '/api/fllws/:username' do
  # if request.method == "POST" and "follow"
  # else if  request.method == "POST" and "unfollow"
end

get '/api/public' do
  @error = public_timeline
  api_response(@error, @messages.map { |msg| {user: msg['username'], content: msg['text'], timestamp: format_datetime(msg['pub_date'])} })
end

post '/api/login' do
  @error = login_user(params['username'], params['password'])
  api_response(@error, "You were logged in")
end

post '/api/register' do
  @error = register_user(params['username'], params['email'], params['password'], params['password'])
  api_response(@error, "You were successfully registered and can login now")
end

get '/api/logout' do
  @error = logout
  api_response(@error, 'You were logged out')
end

post '/api/add_message' do
  @error = post_message(params['text'])
  api_response(@error, 'Your message was recorded')
end

get '/api/:username' do
  @error = user_timeline(params[:username])
  api_response(@error, @messages.map { |msg| { content: msg['text'], timestamp: format_datetime(msg['pub_date']) } })
end

get '/api/:username/follow' do
  @error = follow(params[:username])
  api_response(@error, "You are now following #{params[:username]}")
end

get '/api/:username/unfollow' do
  @error = unfollow(params[:username])
  api_response(@error, "You are no longer following #{params[:username]}")
end