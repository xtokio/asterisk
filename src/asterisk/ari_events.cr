require "http/web_socket"

module Asterisk
  class ARIEvents
    class LoginError < Exception
    end

    class ConnectionLostError < Exception
    end

    def logger
      Asterisk.logger
    end

    class AriJsonDialplan
      JSON.mapping(
        context: String,
        exten: String,
        priority: String
      )
    end
    
    class AriJsonAccountcode
      JSON.mapping(
        dialplan: {type: AriJsonDialplan, nilable: true},
        creationtime: String
      )
    end
    
    class AriJsonConnected
      JSON.mapping(
        name: String,
        number: String
      )
    end
    
    class AriJsonCaller
      JSON.mapping(
        name: String,
        number: String
      )
    end
    
    class AriJsonChannel
      JSON.mapping(
        id: String,
        name: String,
        state: String,
        caller: {type: AriJsonCaller, nilable: true}
      )
    end
    
    class AriJson
      JSON.mapping(
        type: String,
        timestamp: String,
        channel: {type: AriJsonChannel, nilable: true},
        connected: {type: AriJsonConnected, nilable: true},
        accountcode: {type: AriJsonAccountcode, nilable: true},
        asterisk_id: String,
        application: String
      )
    end

    class AriJsonBrigde
      JSON.mapping(
        id: String,
        technology: String,
        bridge_type: String,
        bridge_class: String,
        creator: String,
        name: String,
        video_mode: String
      )
    end

    def initialize(@host = "http://localhost:8088",@events_url = "", @username = "", @secret = "", @ari_app = "")      
      @ws = HTTP::WebSocket.new(URI.parse("#{@host}#{@events_url}?api_key=#{@username}:#{@secret}&app=#{@ari_app}"))
    end

    def register(event,event_type,event_id,event_value,&block)

      spawn do
        @ws.on_message do |message|
          # Ok, we got the message
          if !message.nil?
            json_ws = AriJson.from_json(message)
            puts json_ws.type
            if json_ws.type != "Dial"
              channel = AriJsonChannel.from_json(json_ws.channel.to_json)
              puts channel.id
              puts channel.name
              puts channel.state
            end

            if json_ws.type == event
              if event_type == "channel"
                channel = AriJsonChannel.from_json(json_ws.channel.to_json)
                if channel.id == event_id && channel.state == event_value
                  puts "**************************** Event '#{event}' for event id #{event_id} detected ***********************************"
                  puts "Event value: #{event_value}"
                  block.call
                end
              end
                         
            end

            if json_ws.type == "StasisEnd"
              # ws.close
            end
          end
          puts message
        end
        @ws.run
      end

    end

    def disconect
      @ws.close
    end

  end
end