require "active_record"
require "yaml"

module MiniTwit
  class DbConfig
    def self.setup
      db_config = YAML.load_file(File.join(__dir__, "config", "database.yml"))
      env = ENV["RACK_ENV"] || "development"
      ActiveRecord::Base.configurations = db_config
      ActiveRecord::Base.establish_connection(env.to_sym)
    end
  end
end