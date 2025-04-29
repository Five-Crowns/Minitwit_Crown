# file to set up logging

require "logger"

class JSONLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    base = {
      timestamp: timestamp,
      level: severity
    }

    if msg.is_a?(Hash)
      base.merge!(msg)
    else
      base[:message] = msg.to_s
    end

    base.to_json + "\n"
  end
end

LOG_FILE = File.expand_path("log/minitwit.log", __dir__)

class MinitwitLogger
  def self.logger
    @logger ||= JSONLogger.new(LOG_FILE, "daily")
  end
end
