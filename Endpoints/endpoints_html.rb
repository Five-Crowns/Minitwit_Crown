require_relative 'endpoint_methods'

get '/' do
  if @user.nil?
    redirect to('/public')
  else
    personal_timeline
    erb :timeline
  end
end

get '/public' do
  public_timeline
  erb :timeline
end

get '/login' do
  @error = nil
  @username = nil
  erb :login, layout: :layout
end

post '/login' do
  @error = login_user(params['username'], params['password'])
  if @error.nil?
    redirect to('/')
  else
    erb :login, layout: :layout
  end
end

get '/register' do
  @error = nil
  @username = nil
  @email = nil
  erb :register, layout: :layout
end

post '/register' do
  @error = register_user(params['username'], params['email'], params['password'], params['password2'])
  if @error.nil?
    redirect to('/login')
  else
    erb :register, layout: :layout
  end
end

get '/logout' do
  logout
  redirect to('/public')
end

post '/add_message' do
  @error = post_message(params['text'])
  redirect to('/')
end

get '/:username' do
  user_timeline(params[:username])
  erb :timeline
end

get '/:username/follow' do
  @error = follow(params[:username])
  redirect to("/#{params[:username]}")
end

get '/:username/unfollow' do
  @error = unfollow(params[:username])
  redirect to("/#{params[:username]}")
end