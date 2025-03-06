require 'rake'
require 'sinatra/activerecord/rake'
require 'rspec/core/rake_task'

namespace :db do
  desc 'Migrate the database'
  task :migrate do
    Rake::Task['db:migrate'].invoke
  end

  desc 'Create the database'
  task :create do
    Rake::Task['db:create'].invoke
  end

  desc 'Drop the database'
  task :drop do
    Rake::Task['db:drop'].invoke
  end

  desc 'Seed the database'
  task :seed do
    Rake::Task['db:seed'].invoke
  end

  desc 'Setup the database'
  task :setup => [:create, :migrate, :seed]
end

desc 'Run tests'
RSpec::Core::RakeTask.new(:spec)

desc 'Start the Sinatra application'
task :start do
  sh 'ruby minitwit.rb'
end

task default: :spec