require "socket"
require "time"

module Asterisk
  class AMI
    class LoginError < Exception
    end

    class ConnectionLostError < Exception
    end

    def logger
      Asterisk.logger
    end

    def initialize(@host = "127.0.0.1", @port = "5038", @username = "", @secret = "")
      @conn = TCPSocket.new
      @connected = true
    end

    def connect!
      @conn = TCPSocket.new(@host, @port)
      @conn.tcp_keepalive_interval = 10
      @conn.tcp_keepalive_idle = 5
      @conn.tcp_keepalive_count = 5
      @conn.keepalive = true
      @conn.read_timeout = 5

      login_event = login
      # event_loop if connected?
      login_event
    end

    def disconnect!
      if connected?
        res = send_action( { "Action" => "logoff" } )
        logger.info res
      end
    ensure
      @conn.close rescue nil
      @connected = false
      logger.debug "Disconnected!"
    end

    def login
      send_action!( { "Action" => "login", "username" => "#{@username}", "secret" => "#{@secret}" } )
      login_event = receive_event
      if login_event
        # logger.debug login_event
        if login_event["response"].downcase == "success"
          # FullyBooted should follow after login
          fully_booted_event = receive_event
          if fully_booted_event && fully_booted_event["event"] == "FullyBooted"
            @connected = true
            logger.debug "Connected!"
          else
            disconnect!
          end
        else
          logger.error "Login failed: #{login_event["message"]}"
        end
      else
        logger.error "Login failed (AMI timeout or wrong address, or Asterisk is off - also check manager.conf)"
      end
      login_event
    end

    def connected?
      @connected
    end

    def send_action(action)
      raise LoginError.new("Action should present") unless action.has_key?("Action")
      raise LoginError.new("AMI should be in connected state to send Action") unless connected?

      # actionid is maindatory in order to track action response
      actionid = action["actionid"] ||= Random::Secure.hex(8)
      
      send_action! action

      # Capture and return events from the Asterisk server
      events = Hash(String, String).new

      event1 = receive_event
      event2 = receive_event
      event3 = receive_event

      if !event1.nil?
        events.merge!(event1)
      end
      if !event2.nil?
        events.merge!(event2)
      end
      if !event3.nil?
        events.merge!(event3)
      end

      {"events" => events}
    end

    private def send_action!(action)
      multiline_string = ""
      action.each do |k,v|
        multiline_string += "#{k}: #{v}\r\n"
      end
      multiline_string += "\r\n"

      @conn << multiline_string
    end

    def reconnect!
      logger.info "Reconnecting!"
      disconnect!
      sleep 0.25
      connect!
    rescue
      nil
    end

    # Asterisk manager event is a set of multiple strings with "\r\n" at the end and
    # empty string ("\r\n") terminating event data
    private def receive_event
      event = @conn.gets("\r\n\r\n").to_s.gsub("\r\n\r\n", "")
      logger.debug "Received Asterisk manager event: #{event}"
      event = event.split("\r\n")

      if event == [""]
        # AMI just disconnected, if empty line was received
        @connected = false
        raise ConnectionLostError.new("AMI connection lost")
      else
        parse_event event
      end

    rescue IO::Timeout
      # Unstable connection, causing no event or broken event
      nil
    end

    # parse_event process multi-line array. Normally Asterisk manager event do hold key: value
    # delimited by ':', however there could be an message without delimiter, it will be assigned to the unknown key
    private def parse_event(event : Array)
      result = {} of String => String
      if event.empty?
        nil
      else
        event.each do |line|
          # logger.debug "Processing line: #{line}"
          if /^(.*):(.*)$/ =~ line
            result[$1.to_s.downcase] = $2.to_s.strip
          else
            result["unknown"] ||= ""
            result["unknown"] += line
          end
        end

        result
      end      
    end

  end
end
