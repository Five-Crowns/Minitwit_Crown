require 'sinatra'
require 'sinatra/contrib'
require 'sqlite3'
require 'securerandom'
require 'bcrypt'
require 'time'
require 'sinatra/content_for'
require 'dotenv/load'

helpers Sinatra::ContentFor
set :public_folder, File.dirname(__FILE__) + '/public'
# set :views, File.dirname(__FILE__) + '/views'
set :root, File.dirname(__FILE__) # Explicitly set the root (important!)
set :views, File.join(settings.root, 'views') # Set views relative to root
enable :static

# Configuration
HOST = '0.0.0.0' # Can also insert localhost if you want to run it yourself
PORT = 5000
DATABASE = 'minitwit.db'
SCHEMA_PATH = 'schema.sql'
PER_PAGE = 30
DEBUG = true


# Database connection
def connect_db
  db = SQLite3::Database.new(DATABASE)
  db.results_as_hash = true #Allows accessing record fields by their name
  db
end

# Initialize the database
def init_db
  begin
    db = connect_db
    sql = File.read(SCHEMA_PATH)
    db.execute_batch(sql)
    db.close
    puts "Database initialized successfully."
  rescue => e
    puts "Error initializing database: #{e.message}"
  end
end

# Ensure the database is initialized before the app starts
init_db unless File.exist?(DATABASE)

# Query the database
def query_db(query, *args)
  db = connect_db
  result = db.execute(query, *args)
  db.close
  result
end

# Get user ID
def get_user_id(username)
  result = query_db('SELECT user_id FROM user WHERE username = ?', username)
  result.empty? ? nil : result.first['user_id']
end

# Format datetime
def format_datetime(timestamp)
  Time.at(timestamp).utc.strftime('%Y-%m-%d @ %H:%M')
end

# Gravatar URL
def gravatar_url(email, size = 80)
  "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.strip.downcase)}?d=identicon&s=#{size}"
end

# Formatter for API responses
def api_response(error, success_message)
  if error.nil?
    { status: 'success', message: success_message }.to_json
  else
    { status: 'error', message: error }.to_json
  end
end

# General endpoint methods
def public_timeline
  @messages = query_db("
    SELECT message.*, user.* FROM message, user
    WHERE message.flagged = 0 AND message.author_id = user.user_id
    ORDER BY message.pub_date DESC LIMIT ?", PER_PAGE
  )
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

  @messages = query_db('''
    SELECT message.*, user.* FROM message, user WHERE
    user.user_id = message.author_id AND user.user_id = ?
    ORDER BY message.pub_date DESC LIMIT ?''',
                       [@profile_user['user_id'], PER_PAGE])
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
      'Invalid username or password'
    else
      session[:user_id] = user["user_id"]
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
    nil
  end
end

def logout
  if session[:user_id].nil?
    'You are not logged in'
  else
    session[:user_id] = nil
    nil
  end
end

def add_message(text)
  halt 401 unless session[:user_id]
  if text.nil? || text.empty?
    return "You can't post an empty message."
  end

  query_db(
    'INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
    [session[:user_id], text, Time.now.to_i]
  )
  nil
end

def follow(username)
  halt 401 unless @user
  whom_id = get_user_id(username)
  halt 404 if whom_id.nil?

  query_db(
    'INSERT INTO follower (who_id, whom_id) VALUES (?, ?)',
    [session[:user_id], whom_id]
  )
  nil
end

def unfollow(username)
  halt 401 unless @user
  whom_id = get_user_id(username)
  halt 404 if whom_id.nil?

  query_db(
    'DELETE FROM follower WHERE who_id = ? AND whom_id = ?',
    [session[:user_id], whom_id]
  )
  nil
end

# Sinatra routes
before do
  @db = connect_db
  @user = session[:user_id] ? query_db('SELECT * FROM user WHERE user_id = ?', session[:user_id]).first : nil
end

after do
  @db.close if @db
end

# HTML Endpoints
get '/' do
  if @user.nil?
    redirect to('/public')
  else
    offset = params['offset'] ? params['offset'].to_i : 0
    @messages = query_db("
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id AND (
        user.user_id = ? OR
        user.user_id IN (SELECT whom_id FROM follower WHERE who_id = ?))
      ORDER BY message.pub_date DESC LIMIT ? OFFSET ?",
      [session[:user_id], session[:user_id], PER_PAGE, offset])
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
  @error = add_message(params['text'])
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

# JSON endpoints for the API
before do
  content_type :json if request.path.start_with?('/api/')
end

get '/api/public' do
  @error = public_timeline
  api_response(@error, @messages.map { |msg| {user: msg['username'], text: msg['text'], timestamp: format_datetime(msg['pub_date'])} })
end

post '/api/login' do
  @error = login_user(params['username'], params['password'])
  api_response(@error, "Logged in as #{@username}")
end

post '/api/register' do
  @error = register_user(params['username'], params['email'], params['password'], params['password2'])
  api_response(@error, "Registered as #{@username}")
end

post '/api/logout' do
  @error = logout
  api_response(@error, 'Logged out')
end

post 'api/add_message' do
  @error = add_message(params['text'])
  api_response(@error, 'Message added')
end

get '/api/:username' do
  @error = user_timeline(params[:username])
  api_response(@error, @messages.map { |msg| {text: msg['text'], timestamp: format_datetime(msg['pub_date'])} })
end

post '/api/:username/follow' do
  @error = follow(params[:username])
  api_response(@error, "Now following #{params[:username]}")
end

post '/api/:username/unfollow' do
  @error = unfollow(params[:username])
  api_response(@error, "Unfollowed #{params[:username]}")
end

# Start the Sinatra application
set :bind, HOST
set :port, PORT
set :sessions, true
set :session_secret, ENV['SESSION_SECRET'] || SecureRandom.hex(64)  # Fallback if ENV is missing

Sinatra::Application.run! if __FILE__ == $0