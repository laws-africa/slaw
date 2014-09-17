require 'log4r'

module Slaw
  module Logging
    
    # Get an instance to a logger configured for the class that includes it.
    # This allows log messages to include the class name
    def logger
      return @logger if @logger
      
      @logger = Log4r::Logger[self.class.name] || Log4r::Logger.new(self.class.name)
    end
  end
end
