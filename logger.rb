# file to set up logging

require "json"

class MinitwitLogger
  def self.log(severity, message)
    log_data = {
      timestamp: Time.now.utc.iso8601(3),  # ISO8601 with milliseconds
      severity: severity.to_s.upcase
    }

    # Handle both string messages and structured data
    if message.is_a?(Hash)
      log_data.merge!(message)
    else
      log_data[:message] = message.to_s
    end

    $stdout.puts log_data.to_json
  end
end
