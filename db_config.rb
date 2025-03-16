require "active_record"
require "yaml"
require "erb"  # Add this line

module MiniTwit
  class DbConfig
    def self.setup
      # Load database configuration
      db_yaml = ERB.new(File.read(File.join(__dir__, "config", "database.yml"))).result
      db_config = YAML.load(db_yaml)
      env = ENV["RACK_ENV"] || "development"

      # Establish connection
      ActiveRecord::Base.configurations = db_config
      ActiveRecord::Base.establish_connection(env.to_sym)
      puts "Connected to the database successfully!"
    end
  end
end