#file to set up logging

require 'logger'

class JSONLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    log_entry = {
      timestamp: timestamp,
      level: severity,
      message: msg
    }

    #This converts to JSON for elasticSearch
    "#{log_entry[:timestamp]}:#{log_entry[:level]}: #{msg}\n".to_json
  end
end

LOG_FILE = File.expand_path('log/minitwit.log', __dir__)

class MinitwitLogger
  def self.logger
    @logger ||= JSONLogger.new(LOG_FILE, 'daily')
  end
end