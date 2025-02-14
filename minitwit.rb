require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'digest/md5'
require 'time'




# Configuration
HOST = 'localhost'
PORT = 4567
DATABASE = 'minitwit.db'
PER_PAGE = 30
DEBUG = true
SECRET_KEY = "b634ee133d1c3ff74db375ded3db0aec08f0aabcfa2936d26da1886799367cfbc6285ec5a06841df47cdbe8a3d40127ef838a1cbcd42a5e812277f7fb2802b07"


# Set up Sinatra
set :database, DATABASE
set :sessions, true
set :session_secret, SECRET_KEY
set :public_folder, 'public'
set :views, 'views'

# Database connection helper
def connect_db
  SQLite3::Database.new(DATABASE)
end

# Initialize the database
def init_db
  db = connect_db
  db.execute_batch(File.read('schema.sql'))
  db.close
end

# Query the database and return results as an array of hashes
def query_db(query, args = [], one = false)
  db = connect_db
  results = db.execute(query, args)
  db.close
  results = results.map { |row| Hash[results.columns.zip(row)] }
  one ? results.first : results
end

# Get user ID by username
def get_user_id(username)
  result = query_db('SELECT user_id FROM user WHERE username = ?', [username], true)
  result ? result['user_id'] : nil
end

# Format timestamp for display
def format_datetime(timestamp)
  Time.at(timestamp).strftime('%Y-%m-%d @ %H:%M')
end

# Generate Gravatar URL
def gravatar_url(email, size = 80)
  hash = Digest::MD5.hexdigest(email.strip.downcase)
  "http://www.gravatar.com/avatar/#{hash}?d=identicon&s=#{size}"
end

helpers do
  def content_for(name, &block)
    @content_for ||= {}
    @content_for[name] = capture_haml(&block) # Use capture_haml if using HAML, otherwise just capture(&block)
  end

  def yield_content(name)
    @content_for && @content_for[name] || ""
  end

  def url_for(route_name, params = {})
    # Implement your URL generation logic here.
    if route_name == 'static'
      "/static/#{params[:filename]}"
    else
      "/#{route_name}" # Or more complex logic
    end
  end
end

# Before each request
before do
  @db = connect_db
  @user = nil
  if session[:user_id]
    @user = query_db('SELECT * FROM user WHERE user_id = ?', [session[:user_id]], true)
  end
end

# After each request
after do
  @db.close
end

# Routes
get '/' do
  if !@user
    redirect '/public'
  else
    #offset = params[:offset] || 0
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id AND (
        user.user_id = ? OR
        user.user_id IN (SELECT whom_id FROM follower WHERE who_id = ?))
      ORDER BY message.pub_date DESC LIMIT ?''',
      [session[:user_id], session[:user_id], PER_PAGE])
    erb :timeline
  end
end

get '/public' do
  @messages = query_db('''
    SELECT message.*, user.* FROM message, user
    WHERE message.flagged = 0 AND message.author_id = user.user_id
    ORDER BY message.pub_date DESC LIMIT ?''', [PER_PAGE])
  erb :timeline
end

get '/:username' do
  @profile_user = query_db('SELECT * FROM user WHERE username = ?', [params[:username]], true)
  if @profile_user.nil?
    halt 404, 'User not found'
  end
  @followed = false
  if @user
    @followed = query_db('SELECT 1 FROM follower WHERE who_id = ? AND whom_id = ?',
                         [session[:user_id], @profile_user['user_id']], true) != nil
  end
  @messages = query_db('''
    SELECT message.*, user.* FROM message, user
    WHERE user.user_id = message.author_id AND user.user_id = ?
    ORDER BY message.pub_date DESC LIMIT ?''',
    [@profile_user['user_id'], PER_PAGE])
  erb :timeline
end

get '/:username/follow' do
  unless @user
    halt 401, 'Unauthorized'
  end
  whom_id = get_user_id(params[:username])
  if whom_id.nil?
    halt 404, 'User not found'
  end
  @db.execute('INSERT INTO follower (who_id, whom_id) VALUES (?, ?)',
              [session[:user_id], whom_id])
  @db.commit
  session[:notice] = "You are now following #{params[:username]}"
  redirect "/#{params[:username]}"
end

get '/:username/unfollow' do
  unless @user
    halt 401, 'Unauthorized'
  end
  whom_id = get_user_id(params[:username])
  if whom_id.nil?
    halt 404, 'User not found'
  end
  @db.execute('DELETE FROM follower WHERE who_id = ? AND whom_id = ?',
              [session[:user_id], whom_id])
  @db.commit
  session[:notice] = "You are no longer following #{params[:username]}"
  redirect "/#{params[:username]}"
end

post '/add_message' do
  unless session[:user_id]
    halt 401, 'Unauthorized'
  end
  unless params[:text].empty?
    @db.execute('INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
                [session[:user_id], params[:text], Time.now.to_i])
    @db.commit
    session[:notice] = 'Your message was recorded'
  end
  redirect '/'
end

get '/login' do
  if @user
    redirect '/'
  end
  erb :login
end

post '/login' do
  if @user
    redirect '/'
  end
  user = query_db('SELECT * FROM user WHERE username = ?', [params[:username]], true)
  if user.nil?
    @error = 'Invalid username'
  elsif !BCrypt::Password.new(user['pw_hash']) == params[:password]
    @error = 'Invalid password'
  else
    session[:user_id] = user['user_id']
    session[:notice] = 'You were logged in'
    redirect '/'
  end
  erb :login
end

get '/register' do
  if @user
    redirect '/'
  end
  erb :register
end

post '/register' do
  if @user
    redirect '/'
  end
  @error = nil
  if params[:username].empty?
    @error = 'You have to enter a username'
  elsif params[:email].empty? || !params[:email].include?('@')
    @error = 'You have to enter a valid email address'
  elsif params[:password].empty?
    @error = 'You have to enter a password'
  elsif params[:password] != params[:password2]
    @error = 'The two passwords do not match'
  elsif get_user_id(params[:username])
    @error = 'The username is already taken'
  else
    pw_hash = BCrypt::Password.create(params[:password])
    @db.execute('INSERT INTO user (username, email, pw_hash) VALUES (?, ?, ?)',
               [params[:username], params[:email], pw_hash])
    @db.commit
    session[:notice] = 'You were successfully registered and can login now'
    redirect '/login'
  end
  erb :register
end

get '/logout' do
  session.delete(:user_id)
  session[:notice] = 'You were logged out'
  redirect '/public'
end

# Run the app
if __FILE__ == $0
  init_db
  set :bind, HOST
  set :port, PORT
  set :environment, :development if DEBUG
  Sinatra::Application.run!
end