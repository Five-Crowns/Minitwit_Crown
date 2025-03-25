# Use an official Ruby runtime as the base image
FROM ruby:3.1

# Set the working directory inside the container
WORKDIR /app

# Copy application files
COPY . .

# Install dependencies
RUN gem install bundler
RUN bundle config set --local path 'vendor/bundle'
RUN bundle install

# Expose the port the app will run on
EXPOSE 5000

# Ensures data persistency
RUN mkdir -p /app/data
ENV DB_PATH=/app/data
ENV PATH /usr/local/bundle/bin:$PATH

# Run the Sinatra application when the container starts
CMD ["ruby", "minitwit.rb"]
