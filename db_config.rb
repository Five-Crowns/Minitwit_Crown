require "active_record"
require "yaml"
require "erb"  # Added this line as it is needed for the database.yml to properly evaluate environment variables

module MiniTwit
  class DbConfig
    def self.setup
      # Load database configuration
      db_yaml = ERB.new(File.read(File.join(__dir__, "config", "database.yml"))).result
      db_config = YAML.load(db_yaml)
      env = "default"

      # Establish connection
      ActiveRecord::Base.configurations = db_config
      ActiveRecord::Base.establish_connection(env.to_sym)
      puts "Connected to the database successfully!"
    end
  end
end
