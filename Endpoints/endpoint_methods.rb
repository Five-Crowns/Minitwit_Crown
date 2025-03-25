# NOTE FOR DEVELOPERS!
# PostgreSQL does not use ? for parameterized queries instead use $1, $2.....$n and so on

PER_PAGE = 30
LATEST_FILENAME = 'latest_processed_sim_action_id.txt'

# Sinatra routes


# Now need to remove the query_db method from the endpoint_methods.rb file.
# such that the endpoint_methods.rb file looks like this:
# User.find_by(username: username) instead of querFy_db("SELECT * FROM users WHERE username = ?", username)
before do
  @start_time = Time.now
  Metrics.active_users.increment

  @user_id = session[:id]
  @user = @user_id.nil? ? nil : User.find_by(id: @user_id)
  if request.path.start_with?('/api/')
    content_type :json
    update_latest(params['latest'])
    request_body = request.body.read
    @data = request_body.empty? ? "" : try_parse_json(request_body)
  end
end

after do
  duration = Time.now - @start_time

  # Increment request count
  Metrics.http_requests_total.increment(
    labels: { method: request.request_method, route: request.path, status: response.status }
  )

  # Track request duration
  Metrics.http_request_duration_seconds.observe(
    duration,
    labels: { method: request.request_method, route: request.path, status: response.status }
  )

  # Decrease active users
  Metrics.active_users.decrement
end

def try_parse_json(json)
  JSON.parse(json)
rescue JSON::ParserError, TypeError => e
  halt 400, 'Invalid JSON body'
end

# Updates 'latest' if it isn't nil or empty.
# @param [String] new_latest The value to set 'latest' to.
def update_latest(new_latest)
  return if new_latest.to_s.empty?

  File.write(LATEST_FILENAME, new_latest)
  nil
end

# @return [String] The value of 'latest', or nil if it doesn't exist.
def get_latest
  return nil unless File.exist?(LATEST_FILENAME)

  File.read(LATEST_FILENAME).to_s
end

# Gets a user from their username.
# @param [String] username The username of the user.
# @return Nil, if the user wasn't found. Otherwise, the user object.
def get_user(username)
  User.find_by(username: username)
end

# Gets   user's ID from their username.
# Throws a 404 if the user doesn't exist.
# @param [String] username The username of the user.
# @return [Integer] The user_id of the user.
def get_user_id(username)
  user = get_user(username)
  if user.nil?
    halt 404, '404 User not found'
  else
    user.id
  end
end

# Gets a parameter if it exists, otherwise returns the default value.
# @param [String] param_name The name of the parameter.
# @param [Integer] default_value The value to return if the parameter hasn't been passed.
# @return [Integer] 'params[param_name]' if passed, otherwise 'default_value'.
def get_param_or_default(param_name, default_value)
  val = default_value
  unless params[param_name].nil?
    val = params[param_name].to_i
  end

  val
end

# Generalized query for fetching messages.
# @param [Integer] limit The number of messages you wish to get. (<1 means all messages)
# @param [Integer] user_id The user_id of the user whose messages you wish to get. (<0 means all users)
# @param [Integer] offset The 'index' at which you start getting messages.
# @param [Integer] flagged For if you want to fetch only flagged (or non-flagged) messages.
def get_messages(limit = -1, user_id = -1, offset = -1, flagged = -1)
  messages = Message.joins(:author)
  messages = messages.where(flagged: flagged) if flagged >= 0
  messages = messages.where(author_id: user_id) if user_id >= 0
  messages = messages.order(pub_date: :desc)
  messages = messages.limit(limit) if limit > 0
  messages = messages.offset(offset) if offset > 0
  messages.select('messages.*, users.*')
end

# Generalized query for getting specific page of messages.
# @param [Integer] page What page of messages you want to see. (<1 means first page)
# @param [Integer] user_id The user_id of the user whose messages you wish to get. (<0 means all users)
# @param [Integer] flagged For if you want to fetch only flagged (or non-flagged) messages.
def get_message_page(page = 0, user_id = -1, flagged = -1)
  get_messages(PER_PAGE, user_id, page * PER_PAGE, flagged)
end

# Endpoint Methods

# The users personal timeline, comprised of their own messages and those of whom they follow.
# @param [Integer] user_id The user_id of the user whose personal timeline you wish to see.
# @param [Integer] page What page of messages you want to see.
def personal_timeline(user_id, page = 0)
  followed_ids = Follower.where(whom_id: user_id).pluck(:who_id)
  Message.joins(:author)
         .where(flagged: 0)
         .where(author_id: [user_id, *followed_ids])
         .order(pub_date: :desc)
         .limit(PER_PAGE)
         .offset(page * PER_PAGE)
         .select('messages.*, users.*')
end

# The public timeline containing everyone's messages.
# @param [Integer] page What page of messages you want to see.
def public_timeline(page = 0)
  get_message_page(page, -1, 0)
end

# Messages from a specific user.
# @param [String] username The username of that specific.
# @param [Integer] page What page of messages you want to see.
def user_timeline(username, page = 0)
  user_id = get_user_id(username)
  get_message_page(page, user_id)
end

# Registers a user with the given username, email, and password.
# @param [String] username
# @param [String] email
# @param [String] password
# @param [String] password2
# @return Nil, if user was registered properly. Otherwise, an error message.
def register_user(username, email, password, password2)
  if username.to_s.empty?
    'You have to enter a username'
  elsif email.to_s.empty? || !email.include?('@')
    'You have to enter a valid email address'
  elsif password.to_s.empty?
    'You have to enter a password'
  elsif password != password2
    'The two passwords do not match'
  elsif User.exists?(username: username)
    'The username is already taken'
  else
    pw_hash = BCrypt::Password.create(password)
    User.create(username: username, email: email, pw_hash: pw_hash)
    nil
  end
end

# @param [String] username
# @param [String] password
# @return The user's user_id if log-in was a success. Otherwise, an error message.
def login_user(username, password)
  if username.to_s.empty?
    'You have to enter a username'
  elsif password.to_s.empty?
    'You have to enter a password'
  else
    user = get_user(username)
    if user.nil? || !(BCrypt::Password.new(user.pw_hash) == password)
      'Invalid username or Invalid password'
    else
      user.id
    end
  end
end

# Posts a message as a given user.
# @param [String] text The content of the message to post.
# @param [Integer] user_id The user_id of the author of the message.
# @return Nil, if message was posted properly. Otherwise, an error message.
def post_message(text, user_id)
  if text.to_s.empty?
    return "You can't post an empty message."
  end

  Message.create(author_id: user_id, text: text, pub_date: Time.now.to_i, flagged: 0)
  nil
end

# Checks if 'follower' follows 'followee'.
# @param [Integer] follower_id The user_id of the follower.
# @param [String] followee The username of the followee.
# @return [Boolean] True, if 'follower' follows 'followee'. Otherwise, returns false.
def follows(follower_id, followee)
  followee_user = get_user(followee)
  return false if followee_user.nil?

  followee_id = followee_user.id
  Follower.exists?(who_id:followee_id , whom_id:follower_id )
end

# Makes 'follower' follow 'followee'.
# @param [Integer] follower_id The user_id of the follower.
# @param [String] followee The username of the followee.
# @return Nil, if user was followed properly. Otherwise, an error message.
def follow(follower_id, followee)
  followee_user = get_user(followee)
  return "User #{followee} not found" if followee_user.nil?

  followee_id = followee_user.id

  # Check if trying to follow yourself
  if followee_id == follower_id
    return "You can't follow yourself"
  end

  # Check if already following
  if Follower.exists?(who_id:followee_id , whom_id:follower_id)
    return "You are already following \"#{followee}\""
  end

  Follower.create(who_id: followee_id, whom_id:follower_id )
  nil
end

# Makes 'follower' unfollow 'followee'.
# @param [Integer] follower_id The user_id of the follower.
# @param [String] followee The username of the followee.
# # @return Nil, if user was unfollowed properly. Otherwise, an error message.
def unfollow(follower_id, followee)
  followee_user = get_user(followee)
  return "User #{followee} not found" if followee_user.nil?

  followee_id = followee_user.id

  # Check if trying to unfollow yourself
  if followee_id == follower_id
    return "You can't unfollow yourself"
  end

  # Use direct SQL execution to avoid ActiveRecord issues
  begin
    # Delete using raw SQL to bypass potential ActiveRecord mapping issues
    ActiveRecord::Base.connection.execute(
      "DELETE FROM followers WHERE who_id = #{followee_id} AND whom_id = #{follower_id}"
    )
    nil
  rescue => e
    puts "Error in unfollow: #{e.message}"
    "Database error while unfollowing: #{followee}"
  end
end

# Gets a list of a given user's followers.
# @param [String] username The username of the user whose list of foFllowers you wish to see.
# @param [Integer] limit The max number of followers you wish to see.
def get_followers(username, limit)
  user_id = get_user_id(username)

  # This finds users who follow the specified user
  # The users are the 'who_id' in the Follower table where 'whom_id' is our target user
  User.joins("INNER JOIN followers ON users.id = followers.who_id")
      .where(followers: { whom_id: user_id })
      .limit(limit)
end