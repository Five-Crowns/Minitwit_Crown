require_relative 'endpoint_methods'

# Formatter for API responses
def api_response(error, success_message)
  if error.nil?
    { status: 'success', message: success_message }.to_json
  else
    { status: 'error', message: error }.to_json
  end
end

get '/api/' do
  personal_timeline
  api_response(nil, @messages.map { |msg| {user: msg['username'], text: msg['text'], timestamp: format_datetime(msg['pub_date'])} })
end

get '/api/public' do
  @error = public_timeline
  api_response(@error, @messages.map { |msg| {user: msg['username'], text: msg['text'], timestamp: format_datetime(msg['pub_date'])} })
end

post '/api/login' do
  @error = login_user(params['username'], params['password'])
  api_response(@error, "You were logged in")
end

post '/api/register' do
  @error = register_user(params['username'], params['email'], params['password'], params['password2'])
  api_response(@error, "You were successfully registered and can login now")
end

get '/api/logout' do
  @error = logout
  api_response(@error, 'You were logged out')
end

post '/api/add_message' do
  @error = add_message(params['text'])
  api_response(@error, 'Your message was recorded')
end

get '/api/:username' do
  @error = user_timeline(params[:username])
  api_response(@error, @messages.map { |msg| {text: msg['text'], timestamp: format_datetime(msg['pub_date'])} })
end

get '/api/:username/follow' do
  @error = follow(params[:username])
  api_response(@error, "You are now following #{params[:username]}")
end

get '/api/:username/unfollow' do
  @error = unfollow(params[:username])
  api_response(@error, "You are no longer following #{params[:username]}")
end