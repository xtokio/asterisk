require "log"

module Asterisk
  backend = Log::IOBackend.new
  Log.builder.bind "*", :debug, backend

  def self.logger
    Log
  end
end

