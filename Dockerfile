# Use an official Ruby runtime as the base image
FROM ruby:3.1

# Set the working directory inside the container
WORKDIR /app

# Install required dependencies for the app
RUN apt-get update -qq && apt-get install -y build-essential libsqlite3-dev

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Install the Ruby dependencies using Bundler
RUN bundle install

# Copy the rest of the application files (including views, public, and schema)
COPY . .

# Initialize the database (if not present)
RUN ruby -e "require 'sqlite3'; db = SQLite3::Database.new('/app/minitwit.db'); db.execute_batch(File.read('/app/schema.sql'))"

# Expose the port the app will run on
EXPOSE 5000

# Set environment variables (optional, for production environment)
ENV RACK_ENV=production

# Run the Sinatra application when the container starts
CMD ["ruby", "minitwit.rb"]
