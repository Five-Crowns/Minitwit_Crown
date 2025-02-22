require_relative 'database'

PER_PAGE = 30
LATEST_FILENAME = 'latest_processed_sim_action_id.txt'

# Sinatra routes
before do
  @db = connect_db
  @user = session[:user_id] ? query_db('SELECT * FROM user WHERE user_id = ?', session[:user_id]).first : nil
  if request.path.start_with?('/api/')
    content_type :json
    update_latest
  end
end

after do
  @db.close if @db
end

# Latest handling
def update_latest
  latest = params['latest']
  return if latest.nil? || latest.empty?

  write_latest(latest)
end

def get_latest
  return nil unless File.exist?(LATEST_FILENAME)

  File.read(LATEST_FILENAME)
end

def write_latest(latest)
  File.write(LATEST_FILENAME, latest)
end

# Get user ID
def get_user_id(username)
  result = query_db('SELECT user_id FROM user WHERE username = ?', username)
  user_id = result.empty? ? nil : result.first['user_id']
  halt 404 if user_id.nil?

  user_id
end

# General query for messages
def get_messages(limit = -1, user = -1, flagged = -1)
  q_select = "SELECT message.*, user.* FROM message, user "

  q_where = "WHERE message.author_id = user.user_id "
  q_where += "AND message.flagged = #{flagged} " if flagged >= 0
  q_where += "AND user.user_id = #{user} " if user >= 0

  q_order = "ORDER BY message.pub_date DESC "
  q_order += "LIMIT #{limit} " if limit > 0

  query_string = q_select + q_where + q_order
  query_db(query_string)
end

# Endpoint Methods
def personal_timeline
  offset = params['offset'] ? params['offset'].to_i : 0
  @messages = query_db("
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id AND (
        user.user_id = ? OR
        user.user_id IN (SELECT whom_id FROM follower WHERE who_id = ?))
      ORDER BY message.pub_date DESC LIMIT ? OFFSET ?",
                       [session[:user_id], session[:user_id], PER_PAGE, offset])
end

def public_timeline
  @messages = get_messages(PER_PAGE, -1, 0)
  nil
end

def user_timeline(username)
  @profile_user = query_db('SELECT * FROM user WHERE username = ?', username).first
  halt 404 if @profile_user.nil?

  @followed = false
  if @user
    @followed = !query_db(
      'SELECT 1 FROM follower WHERE follower.who_id = ? AND follower.whom_id = ?',
      [session[:user_id], @profile_user['user_id']]
    ).empty?
  end

  @messages = get_messages(PER_PAGE, @profile_user['user_id'])
  nil
end

def login_user(username, password)
  if !session[:user_id].nil?
    'You are already logged in'
  elsif username.to_s.empty?
    'You have to enter a username'
  elsif password.to_s.empty?
    'You have to enter a password'
  else
    @username = username
    user = query_db('SELECT * FROM user WHERE username = ?', username).first
    if user.nil? || !(BCrypt::Password.new(user["pw_hash"]) == password)
      'Invalid username or Invalid password'
    else
      session[:user_id] = user["user_id"]
      session[:success_message] = 'You were logged in'
      nil
    end
  end
end

def register_user(username, email, password, password2)
  @username = username
  @email = email

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
    session[:success_message] = 'You were successfully registered and can login now'
    nil
  end
end

def logout
  session[:user_id] = nil
  session[:success_message] = 'You were logged out'
  nil
end

def post_message(text, user = -1)
  user_id = session[:user_id]
  user_id = user if user > 0

  halt 401 unless user_id
  if text.nil? || text.empty?
    return "You can't post an empty message."
  end

  query_db(
    'INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
    [user_id, text, Time.now.to_i]
  )
  session[:success_message] = 'Your message was recorded'
  nil
end

def follow(follower_id, follows)
  follows_id = get_user_id(follows)

  query_db(
    'INSERT INTO follower (who_id, whom_id) VALUES (?, ?)',
    [follower_id, follows_id]
  )
  session[:success_message] = "You are now following \"#{follows}\""
  nil
end

def unfollow(follower_id, follows)
  follows_id = get_user_id(follows)

  query_db(
    'DELETE FROM follower WHERE who_id = ? AND whom_id = ?',
    [follower_id, follows_id]
  )
  session[:success_message] = "You are no longer following \"#{follows}\""
  nil
end

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