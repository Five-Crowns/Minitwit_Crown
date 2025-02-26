#!/bin/bash

# Start minitwit.rb in the background
ruby minitwit.rb &

# Wait for the app to start
sleep 5

# Run the tests
rspec Test/minitwit_tests_spec.rb || echo "RSpec tests failed!"
pytest Test/minitwit_sim_api_test.py || echo "Python tests failed!"

# Optionally kill the app after tests complete
pkill -f "ruby minitwit.rb"