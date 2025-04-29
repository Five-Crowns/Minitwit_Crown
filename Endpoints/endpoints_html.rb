require_relative "endpoint_methods"

get "/" do
  if @user.nil?
    redirect to("/public")
  else
    page = get_param_or_default("page", 0)
    @messages = personal_timeline(@user_id, page)
    erb :timeline
  end
end

get "/public" do
  page = get_param_or_default("page", 0)
  @messages = public_timeline(page)
  erb :timeline
end

get "/login" do
  unless @user_id.nil?
    session[:success_message] = "You are already logged in"
    redirect to("/")
    return
  end

  @error = nil
  @username = nil
  erb :login, layout: :layout
end

post "/login" do
  @username = params["username"]
  response = login_user(@username, params["password"])
  if response.is_a?(Integer)
    session[:user_id] = response.to_i
    session[:success_message] = "You were logged in"
    log_event("User #{@username} successfully logged in")
    redirect to("/")
  else
    @error = response
    log_event("User #{@username} failed to log in with error #{@error}")
    erb :login, layout: :layout
  end
end

get "/register" do
  @error = nil
  @username = nil
  @email = nil
  erb :register, layout: :layout
end

post "/register" do
  @username = params["username"]
  @email = params["email"]
  @error = register_user(@username, @email, params["password"], params["password2"])
  if @error.nil?
    session[:success_message] = "You were successfully registered and can login now"
    log_event("User #{@username} successfully registered")
    redirect to("/login")
  else
    log_event("User #{@username} failed to register with error #{@error}")
    erb :register, layout: :layout
  end
end

get "/logout" do
  session[:user_id] = nil
  session[:success_message] = "You were logged out"
  redirect to("/public")
end

post "/add_message" do
  halt 401 unless @user
  @error = post_message(params["text"], @user_id)
  if @error.nil?
    log_event("Posting message")
    session[:success_message] = "Your message was recorded"
  else
    log_event("Failed to add message with error #{@error}")
    @error
  end
  redirect to("/")
end

get "/:username" do
  page_user = params[:username]
  @profile_user = get_user(page_user)
  halt 404, "404 User not found" if @profile_user.nil?

  # Check if this is the current user's profile
  @is_current_user = @user && @user.username == page_user

  # Only check follow status if viewing someone else's profile
  @followed = (!@is_current_user && @user) ? follows(@user_id, page_user) : false

  @messages = user_timeline(page_user)
  erb :timeline
end

get "/:username/follow" do
  halt 401 unless @user
  followee = params[:username]

  @error = follow(@user_id, followee)
  session[:success_message] = @error.nil? ? "You are now following \"#{followee}\"" : @error
  redirect to("/#{params[:username]}")
end

get "/:username/unfollow" do
  halt 401 unless @user
  followee = params[:username]

  @error = unfollow(@user_id, followee)
  session[:success_message] = @error.nil? ? "You are no longer following \"#{followee}\"" : @error
  redirect to("/#{params[:username]}")
end
