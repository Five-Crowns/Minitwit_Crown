require 'rspec'
require 'rack/test'
require 'sqlite3'
require_relative '../minitwit'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  config.before(:suite) do
    db = SQLite3::Database.new(':memory:')
    db.results_as_hash = true
    schema = File.read(File.join(File.dirname(__FILE__), '../schema.sql'))
    db.execute_batch(schema)

    Thread.new do
      Sinatra::Application.run!
    end
    sleep 2 # Give the server time to start
  end

  config.after(:suite) do
    db.close if db
  end
end