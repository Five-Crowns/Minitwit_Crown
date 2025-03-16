# NOTE FOR DEVELOPERS!
# You may find these commands useful if you want to run the project locally
# We now spin up two separate containers
# docker compose -f docker-compose.local.yml down
# docker build -t postgresqlimage -f Dockerfile.postgresql .
# docker build -t minitwitimage -f Dockerfile.app .
# docker compose -f docker-compose.local.yml up

# Load database configuration
db_config = YAML.load_file('database.yml')['development']

# Establish connection
ActiveRecord::Base.establish_connection(db_config)

puts "Connected to the database successfully!"