require_relative 'database'

PER_PAGE = 30
LATEST_FILENAME = 'latest_processed_sim_action_id.txt'

# Sinatra routes

before do
  @db = connect_db
  @user_id = session[:user_id]
  @user = @user_id.nil? ?
            nil :
            query_db('SELECT * FROM user WHERE user_id = ?', @user_id).first
  if request.path.start_with?('/api/')
    content_type :json
    update_latest(params['latest'])
    request_body = request.body.read
    @data = request_body.empty? ? "" : try_parse_json(request_body)
  end
end

after do
  @db.close if @db
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
  query_db('SELECT * FROM user WHERE username = ?', username).first
end

# Gets a user's ID from their username.
# Throws a 404 if the user doesn't exist.
# @param [String] username The username of the user.
# @return [Integer] The user_id of the user.
def get_user_id(username)
  user = get_user(username)
  if user.nil?
    halt 404, '404 User not found'
  else
    user['user_id']
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
  q_select = "SELECT message.*, user.* FROM message, user "

  q_where = "WHERE message.author_id = user.user_id "
  q_where += "AND message.flagged = #{flagged} " if flagged >= 0
  q_where += "AND user.user_id = #{user_id} " if user_id >= 0

  q_order = "ORDER BY message.pub_date DESC "
  q_order += "LIMIT #{limit} " if limit > 0
  q_order += "OFFSET #{offset} " if offset > 0

  query_string = q_select + q_where + q_order
  query_db(query_string)
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
  query_db('
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id AND (
        user.user_id = ? OR
        user.user_id IN (SELECT whom_id FROM follower WHERE who_id = ?))
      ORDER BY message.pub_date DESC
      LIMIT ?
      OFFSET ?',
                       [user_id, user_id, PER_PAGE, page * PER_PAGE])
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
  elsif !query_db('SELECT user_id FROM user WHERE username = ?', username).empty?
    'The username is already taken'
  else
    pw_hash = BCrypt::Password.create(password)
    query_db(
      'INSERT INTO user (username, email, pw_hash) VALUES (?, ?, ?)',
      [username, email, pw_hash]
    )
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
    if user.nil? || !(BCrypt::Password.new(user["pw_hash"]) == password)
      'Invalid username or Invalid password'
    else
      return user["user_id"]
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

  query_db(
    'INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
    [user_id, text, Time.now.to_i]
  )
  nil
end

# Checks if 'follower' follows 'followee'.
# @param [Integer] follower_id The user_id of the follower.
# @param [String] followee The username of the followee.
# @return [Boolean] True, if 'follower' follows 'followee'. Otherwise, returns false.
def follows(follower_id, followee)
  followee_id = get_user_id(followee)
  result = query_db('
    SELECT 1
    FROM follower
    WHERE follower.who_id = ? AND follower.whom_id = ?',
                    [follower_id, followee_id]
  )
  !result.empty?
end

# Makes 'follower' follow 'followee'.
# @param [Integer] follower_id The user_id of the follower.
# @param [String] followee The username of the followee.
# @return Nil, if user was followed properly. Otherwise, an error message.
def follow(follower_id, followee)
  already_following = follows(follower_id, followee)
  if already_following
    return "You are already following \"#{followee}\""
  end

  followee_id = get_user_id(followee)
  if followee_id == follower_id
    return "You can't follow yourself"
  end

  query_db(
    'INSERT INTO follower (who_id, whom_id) VALUES (?, ?)',
    [follower_id, followee_id]
  )
  nil
end

# Makes 'follower' unfollow 'followee'.
# @param [Integer] follower_id The user_id of the follower.
# @param [String] followee The username of the followee.
# # @return Nil, if user was unfollowed properly. Otherwise, an error message.
def unfollow(follower_id, followee)
  already_following = follows(follower_id, followee)
  unless already_following
    return "You were never following \"#{followee}\""
  end

  followee_id = get_user_id(followee)
  if followee_id == follower_id
    return "Now that's just kinda sad..."
  end

  query_db(
    'DELETE FROM follower WHERE who_id = ? AND whom_id = ?',
    [follower_id, followee_id]
  )
  nil
end

# Gets a list of a given user's followers.
# @param [String] username The username of the user whose list of followers you wish to see.
# @param [Integer] limit The max number of followers you wish to see.
def get_followers(username, limit)
  whom_id = get_user_id(username)
  query_db(
    'SELECT user.username
     FROM user
     INNER JOIN follower ON follower.whom_id = user.user_id
     WHERE follower.who_id = ?
     LIMIT ?',
    [whom_id, limit])
end