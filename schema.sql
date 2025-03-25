-- Manually ensure the database exists before running this script
-- CREATE DATABASE should be run separately
-- Run this in the psql shell: CREATE DATABASE minitwit;

-- Connect to the database (only needed in psql shell)
-- \c minitwit;

-- Drop tables in the correct order to avoid foreign key issues
DROP TABLE IF EXISTS follower;
DROP TABLE IF EXISTS message;
DROP TABLE IF EXISTS usr;

-- Create the table "usr" instead of "users" as user is a reserved keyword
CREATE TABLE usr (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR NOT NULL UNIQUE,
  email VARCHAR NOT NULL UNIQUE,
  pw_hash VARCHAR NOT NULL
);

-- Create the follower table
CREATE TABLE follower (
  who_id INTEGER REFERENCES usr(user_id) ON DELETE CASCADE,
  whom_id INTEGER REFERENCES usr(user_id) ON DELETE CASCADE,
  PRIMARY KEY (who_id, whom_id) -- Prevent duplicate follow relationships
);

-- Create the message table
CREATE TABLE message (
  message_id SERIAL PRIMARY KEY,
  author_id INTEGER NOT NULL REFERENCES usr(user_id) ON DELETE CASCADE,
  text TEXT NOT NULL, -- TEXT is better for longer messages
  pub_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  flagged BOOLEAN DEFAULT FALSE -- Use BOOLEAN instead of INTEGER for flags
);
