# file to set up logging

require "logger"

class JSONLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    {
      timestamp: timestamp,
      level: severity,
      message: msg
    }.to_json + "\n"
  end
end

LOG_FILE = File.expand_path("log/minitwit.log", __dir__)

class MinitwitLogger
  def self.logger
    @logger ||= JSONLogger.new(LOG_FILE, "daily")
  end
end
