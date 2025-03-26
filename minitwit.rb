require "sinatra"
require "sinatra/contrib"
require "sqlite3"
require "securerandom"
require "bcrypt"
require "time"
require "sinatra/content_for"
require "dotenv/load"
require "pg"
require "active_record"
require "yaml"
require "./models/user"
require "prometheus/middleware/exporter"
require_relative "db_config"

# Initialize database connection
MiniTwit::DbConfig.setup

require_relative "Endpoints/endpoints_html"
require_relative "Endpoints/endpoints_api"
require_relative "models/user"
require_relative "models/message"
require_relative "models/follower"

# TODO this fixed the 403 on /metrics, but unsure why
# See if it can be fixed without production environment
set :environment, :production

configure do
  set :protection,
    allowed_hosts: [
      "localhost",
      "127.0.0.1",
      "minitwit",
      "app"
    ]
end

helpers Sinatra::ContentFor
set :public_folder, File.dirname(__FILE__) + "/public"
# set :views, File.dirname(__FILE__) + '/views'
set :root, File.dirname(__FILE__) # Explicitly set the root (important!)
set :views, File.join(settings.root, "views") # Set views relative to root
enable :static

use Prometheus::Middleware::Exporter

# Configuration
HOST = "0.0.0.0" # Can also insert localhost instead of 0.0.0.0 if you want to run it yourself
PORT = 5000
DEBUG = true

helpers do
  # Escape HTML characters
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

# Format datetime
def format_datetime(timestamp)
  time = Time.at(timestamp).getlocal
  time.strftime("%Y-%m-%d @ %H:%M:%S")
end

# Gravatar URL
def gravatar_url(email, size = 80)
  email = email.to_s.strip.downcase
  "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}?d=identicon&s=#{size}"
end

# Start the Sinatra application
set :bind, HOST
set :port, PORT
set :sessions, true
set :session_secret, ENV["SESSION_SECRET"] || SecureRandom.hex(64)  # Fallback if ENV is missing

Sinatra::Application.run! if __FILE__ == $0
