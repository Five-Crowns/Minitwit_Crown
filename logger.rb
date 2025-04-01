#file to set up logging

require 'logger'

LOG_FILE = File.expand_path('log/minitwit.log', __dir__)

class MinitwitLogger
  def self.logger
    @logger ||= Logger.new(LOG_FILE, 'daily')
  end
end