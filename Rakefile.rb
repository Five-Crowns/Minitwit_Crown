require "active_record"
require "fileutils"
require_relative "db_config"

include ActiveRecord::Tasks

namespace :db do
  task :environment do
    MiniTwit::DbConfig.setup
  end

  task :load_config => :environment do
    # Configure database tasks
    DatabaseTasks.tap do |config|
      config.db_dir = "db"
      config.migrations_paths = ["db/migrate"]
      config.seed_loader = nil
      config.env = ENV["RACK_ENV"] || "development"
      config.database_configuration = ActiveRecord::Base.configurations
      config.root = File.expand_path("..", __FILE__)
    end
  end

  desc "Create the database"
  task create: :load_config do
    DatabaseTasks.create_current
  end

  desc "Drop the database"
  task drop: :load_config do
    DatabaseTasks.drop_current
  end

  desc "Migrate the database"
  task migrate: :load_config do
    DatabaseTasks.migrate
  end

  desc "Rollback last migration"
  task rollback: :load_config do
    step = ENV["STEP"] ? ENV["STEP"].to_i : 1
    ActiveRecord::Base.connection.migration_context.rollback(step)
  end

  desc "Reset database"
  task reset: [:drop, :create, :migrate]

  namespace :schema do
    desc "Create schema.rb file"
    task dump: :load_config do
      require "active_record/schema_dumper"
      filename = ENV["SCHEMA"] || File.join(DatabaseTasks.db_dir, "schema.rb")
      File.open(filename, "w:utf-8") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.lease_connection, file)
      end
    end


    desc "Load schema.rb file"
    task load: :load_config do
      filename = ENV["SCHEMA"] || File.join(DatabaseTasks.db_dir, "schema.rb")
      load(filename) if File.exist?(filename)
    end
  end
end