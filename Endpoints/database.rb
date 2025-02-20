DATABASE = 'minitwit.db'
SCHEMA_PATH = 'schema.sql'

# Database connection
def connect_db
  db = SQLite3::Database.new(DATABASE)
  db.results_as_hash = true #Allows accessing record fields by their name
  db
end

# Initialize the database
def init_db
  begin
    db = connect_db
    sql = File.read(SCHEMA_PATH)
    db.execute_batch(sql)
    db.close
    puts "Database initialized successfully."
  rescue => e
    puts "Error initializing database: #{e.message}"
  end
end

# Ensure the database is initialized before the app starts
init_db unless File.exist?(DATABASE)

# Query the database
def query_db(query, *args)
  db = connect_db
  result = db.execute(query, *args)
  db.close
  result
end