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
        playback: {type: AriJsonPlayback, nilable: true},
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

    class AriJsonPlayback
      JSON.mapping(
        id: String,
        media_uri: String,
        target_uri: String,
        language: String,
        state: String
      )
    end

    class AriJsonPlay
      JSON.mapping(
        type: String,
        playback: {type: AriJsonPlayback, nilable: true},
        asterisk_id: String,
        application: String
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
            message_type = JSON.parse(message)["type"]
            custom_json = {"type"=> message_type, "id"=>"", "name"=>"", "state"=>""}

            if message_type != "Dial"
              if message_type == "PlaybackStarted" || message_type == "PlaybackFinished"
                message_json = AriJsonPlay.from_json(message)
                message_playback = AriJsonPlayback.from_json(message_json.playback.to_json)
                custom_json["id"] = message_playback.id
                custom_json["name"] = "Play"
                custom_json["state"] = message_playback.state
              else
                message_json = AriJson.from_json(message)
                channel = AriJsonChannel.from_json(message_json.channel.to_json)
                custom_json["id"] = channel.id
                custom_json["name"] = channel.name
                custom_json["state"] = channel.state
              end
            end

            puts "============================================= Message ================================================="
            puts message
            puts custom_json

            if message_type == event
              if event_type == "channel"
                if custom_json["id"] == event_id && custom_json["state"] == event_value
                  puts "**************************** Event '#{event}' for event id #{event_id} detected ***********************************"
                  puts "Event value: #{event_value}"
                  block.call
                end
              end        
            end

            if message_type == "StasisEnd"
              # ws.close
            end
          end
          # puts message
        end
        @ws.run
      end

    end

    def disconect
      @ws.close
    end

  end
end