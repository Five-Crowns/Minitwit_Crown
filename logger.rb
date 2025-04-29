# file to set up logging

require "json"

class MinitwitLogger
  def self.log(severity, message, request, user_id)
    log_data = {
      timestamp: Time.now.utc.iso8601(3),  # ISO8601 with milliseconds
      severity: severity.to_s.upcase,
      user_ip: request.ip,
      user_id: user_id || "Anonymous User",
      request_type: request.request_method,
      endpoint: request.path_info
    }

    # Handle both string messages and structured data
    if message.is_a?(Hash)
      log_data.merge!(message)
    else
      log_data[:message] = message.to_s
    end

    STDOUT.puts log_data.to_json
  end
end
