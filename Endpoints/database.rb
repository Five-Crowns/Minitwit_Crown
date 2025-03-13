# NOTE FOR DEVELOPERS!
# You may find these commands useful if you want to run the project locally
# We now spin up two separate containers
# docker compose -f docker-compose.local.yml down
# docker build -t postgresqlimage -f Dockerfile.postgresql .
# docker build -t minitwitimage -f Dockerfile.app .
# docker compose -f docker-compose.local.yml up

SCHEMA_PATH = 'schema.sql'

# @return A connection to the database.
def connect_db
  retry_count = 0
  max_retries = 5

  begin
    db = PG.connect(
      dbname: "minitwit", 
      user: "root", 
      password: "root",
      host: "minitwit_postgresql",
      port: 5432
    )
    puts 'Connection to the database established successfully.'
    # automatically converts query results into Ruby-native types
    db.type_map_for_results = PG::BasicTypeMapForResults.new(db)
    db
  rescue PG::Error => e
    retry_count += 1
    if retry_count <= max_retries
      puts "Connection attempt #{retry_count} failed: #{e.message}"
      puts "Retrying in 5 seconds..."
      sleep 5
      retry
    else
      puts "Failed to connect after #{max_retries} attempts: #{e.message}"
      raise e
    end
  end
end

# Ensure the database is initialized before the app starts
# init_db unless File.exist?(DATABASE)
connect_db
  
# Query the database
# @param [String] query The SQL query to execute on the database.
# @param args A list of arguments to insert into the query; works by mapping each "?" to each argument.
def query_db(query, *args)
  db = connect_db
  result = db.exec(query, *args)
  db.close
  result
end