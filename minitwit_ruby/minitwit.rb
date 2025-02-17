require 'sinatra'
require 'sinatra/contrib'
require 'sqlite3'
require 'securerandom'
require 'bcrypt'
require 'time'
require 'sinatra/content_for'

helpers Sinatra::ContentFor
set :public_folder, File.dirname(__FILE__) + '/public'
# set :views, File.dirname(__FILE__) + '/views'
set :root, File.dirname(__FILE__) # Explicitly set the root (important!)
set :views, File.join(settings.root, 'views') # Set views relative to root
enable :static

# Configuration
HOST = 'localhost'
PORT = 5000
DATABASE = 'minitwit.db'
SCHEMA_PATH = 'schema.sql'
PER_PAGE = 30
DEBUG = true
SECRET_KEY = SecureRandom.hex(64)  # Generate a 64-byte secret key

# Database connection
def connect_db
  db = SQLite3::Database.new(DATABASE)
  db.results_as_hash = true
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
init_db if !File.exist?(DATABASE)

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
  result.empty? ? nil : result[0][0]
end

# Format datetime
def format_datetime(timestamp)
  Time.at(timestamp).utc.strftime('%Y-%m-%d @ %H:%M')
end

# Gravatar URL
def gravatar_url(email, size = 80)
  "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.strip.downcase)}?d=identicon&s=#{size}"
end

# Sinatra routes
before do
  @db = connect_db
  @user = session[:user_id] ? query_db('SELECT * FROM user WHERE user_id = ?', session[:user_id]).first : nil
end

after do
  @db.close if @db
end

get '/' do
  if @user.nil?
    redirect to('/public')
  else
    offset = params['offset'] ? params['offset'].to_i : 0
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id AND (
        user.user_id = ? OR
        user.user_id IN (SELECT whom_id FROM follower WHERE who_id = ?))
      ORDER BY message.pub_date DESC LIMIT ? OFFSET ?''',
      [session[:user_id], session[:user_id], PER_PAGE, offset])
    erb :timeline
  end
end

get '/public' do
  @messages = query_db('''
    SELECT message.*, user.* FROM message, user
    WHERE message.flagged = 0 AND message.author_id = user.user_id
    ORDER BY message.pub_date DESC LIMIT ?''', PER_PAGE)
  erb :timeline
end

get '/login' do
  @error = nil
  @username = nil
  erb :login, layout: :layout
end

post '/login' do
  user = query_db('SELECT * FROM user WHERE username = ?', params['username']).first
  if user.nil? || !(BCrypt::Password.new(user["pw_hash"]) == params['password'])
    @error = 'Invalid username or password'
    @username = params['username']
    erb :login, layout: :layout
  else
    session[:user_id] = user["user_id"]
    redirect to('/')
  end
end

get '/register' do
  @error = nil
  @username = nil
  @email = nil
  erb :register, layout: :layout
end

post '/register' do
  @error = nil
  @username = params['username']
  @email = params['email']

  if params['username'].to_s.empty?
    @error = 'You have to enter a username'
  elsif params['email'].to_s.empty? || !params['email'].include?('@')
    @error = 'You have to enter a valid email address'
  elsif params['password'].to_s.empty?
    @error = 'You have to enter a password'
  elsif params['password'] != params['password2']
    @error = 'The two passwords do not match'
  elsif !query_db('SELECT user_id FROM user WHERE username = ?', params['username']).empty?
    @error = 'The username is already taken'
  else
    pw_hash = BCrypt::Password.create(params['password'])
    query_db('INSERT INTO user (username, email, pw_hash) VALUES (?, ?, ?)',
              [params['username'], params['email'], pw_hash])
    redirect to('/login')
  end
  
  erb :register, layout: :layout
end

get '/logout' do
  session[:user_id] = nil
  redirect to('/public')
end

get '/:username' do
  profile_user = query_db('SELECT * FROM user WHERE username = ?', params[:username]).first
  halt 404 if profile_user.nil?

  followed = false
  if @user
    followed = !query_db('SELECT 1 FROM follower WHERE follower.who_id = ? AND follower.whom_id = ?',
                          session[:user_id], profile_user['user_id']).empty?
  end

  @messages = query_db('''
    SELECT message.*, user.* FROM message, user WHERE
    user.user_id = message.author_id AND user.user_id = ?
    ORDER BY message.pub_date DESC LIMIT ?''',
    profile_user['user_id'], PER_PAGE)

  erb :timeline, locals: { followed: followed, profile_user: profile_user }
end

get '/:username/follow' do
  halt 401 unless @user
  whom_id = get_user_id(params[:username])
  halt 404 if whom_id.nil?

  @db.execute('INSERT INTO follower (who_id, whom_id) VALUES (?, ?)', session[:user_id], whom_id)
  redirect to("/#{params[:username]}")
end

get '/:username/unfollow' do
  halt 401 unless @user
  whom_id = get_user_id(params[:username])
  halt 404 if whom_id.nil?

  @db.execute('DELETE FROM follower WHERE who_id = ? AND whom_id = ?', session[:user_id], whom_id)
  redirect to("/#{params[:username]}")
end

post '/add_message' do
  halt 401 unless session[:user_id]
  if params['text'] && !params['text'].empty?
    @db.execute('INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
                [session[:user_id], params['text'], Time.now.to_i])
    redirect to('/')
  end
end

# Start the Sinatra application
set :bind, HOST
set :port, PORT
set :sessions, true
set :session_secret, SECRET_KEY

Sinatra::Application.run! if __FILE__ == $0