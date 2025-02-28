#!/bin/bash

# Start minitwit.rb in the background
ruby minitwit.rb &

# Wait for the app to start
sleep 5

# Run the tests
rspec Test/minitwit_tests_spec.rb
RSPEC_EXIT=$?

pytest Test/minitwit_sim_api_test.py 
PYTEST_EXIT=$?

echo "Test codes:"
echo "RSPEC_EXIT: $RSPEC_EXIT"
echo "PYTEST_EXIT: $PYTEST_EXIT"

# Exit with failure if any of the tests failed
if [ $RSPEC_EXIT -ne 0 ] || [ $PYTEST_EXIT -ne 0 ]; then
    echo "Tests failed! Aborting deployment."
  exit 1
fi