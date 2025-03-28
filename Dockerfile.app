# Use an official Ruby runtime as the base image
FROM ruby:3.1

# Set the working directory inside the container
WORKDIR /app

# Copy application files
COPY . .

# Install dependencies
RUN gem install bundler && bundle install

# Expose the port the app will run on
EXPOSE 5000

# Accept build arguments for environment variables
ARG POSTGRES_USER
ARG POSTGRES_PASSWORD
ARG POSTGRES_DB
ARG POSTGRES_HOST

# Set environment variables inside the container
ENV POSTGRES_USER=$POSTGRES_USER
ENV POSTGRES_PASSWORD=$POSTGRES_PASSWORD
ENV POSTGRES_DB=$POSTGRES_DB
ENV POSTGRES_HOST=$POSTGRES_HOST

# Ensures data persistency
RUN mkdir -p /app/data
ENV DB_PATH=/app/data

# Run the Sinatra application when the container starts
CMD ["ruby", "minitwit.rb"]
