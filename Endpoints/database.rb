# DATABASE = 'minitwit.db'
DATABASE = File.join(ENV['DB_PATH'] || 'data', 'minitwit.db')
Dir.mkdir(File.dirname(DATABASE)) unless Dir.exist?(File.dirname(DATABASE))
SCHEMA_PATH = 'schema.sql'

# @return A connection to the database.
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
# @param [String] query The SQL query to execute on the database.
# @param args A list of arguments to insert into the query; works by mapping each "?" to each argument.
def query_db(query, *args)
  db = connect_db
  result = db.execute(query, *args)
  db.close
  result
end