require "http/client"
require "json"
require "random/secure"

module Asterisk
  class ARI
    class LoginError < Exception
    end

    class ConnectionLostError < Exception
    end

    def logger
      Asterisk.logger
    end

    class AriJsonMessage
      JSON.mapping(
        message: String
      )
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
        channels: Array(String),
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

    def initialize(@host = "http://localhost:8088", @websocket_host = "ws://localhost:8088", @ari_app = "", @username = "", @secret = "")
      uri = URI.parse(@host)
      @client = HTTP::Client.new(uri)
      @client.basic_auth(@username,@secret)

      @channel_message = Channel(String).new
      start_websocket()
    end

    # Creates a new bridge
    def bridge_new
      bridge_id = Random::Secure.hex(8)
      client_response = @client.post("/ari/bridges/#{bridge_id}")
      code = client_response.status_code
      json = AriJsonBrigde.from_json(client_response.body)
      
      {
        "code"=>code,
        "id"=>json.id, 
        "technology"=>json.technology, 
        "bridge_type"=>json.bridge_type, 
        "bridge_class"=>json.bridge_class, 
        "creator"=>json.creator, "name"=>json.name, 
        "video_mode"=>json.video_mode
      }
    end

    # Gets Bridge details
    def bridge_details(bridge_id)
      client_response = @client.get("/ari/bridges/#{bridge_id}")
      code = client_response.status_code
      if client_response.body.includes?("message")
        json_bridge = AriJsonMessage.from_json(client_response.body)
      else
        json_bridge = AriJsonBrigde.from_json(client_response.body)
      end
      json_bridge
    end

    # Removes a bridge
    def bridge_hangup(bridge_id)
      response = @client.delete("/ari/bridges/#{bridge_id}")
      code = response.status_code
      json = response.body
      if json == ""
        json = "Bridge hangup"
      end
      {"code"=>code, "id"=>bridge_id, "message"=>json}
    end

    # Creates a new channel
    def channel_new(endpoint,ari_app)
      client_response = @client.post("/ari/channels/create?endpoint=#{endpoint}&app=#{ari_app}")
      code = client_response.status_code
      if code == 200
        json = AriJsonChannel.from_json(client_response.body)
        response = {
          "code"=>code,
          "id"=>json.id,
          "name"=>json.name,
          "state"=>json.state
        }
      else
        response = client_response.body
      end

      response
    end

    # Channel details
    def channel_details(channel_id)
      response = @client.get("/ari/channels/#{channel_id}")
      code = response.status_code
      channel_json = response.body
      if response.body.includes?("message")
        channel_json = AriJsonMessage.from_json(response.body)
      else
        channel_json = AriJsonChannel.from_json(response.body)
      end
      channel_json
    end

    # Hangup a channel id
    def channel_hangup(channel_id)
      response = @client.delete("/ari/channels/#{channel_id}")
      code = response.status_code
      json = response.body
      if json == ""
        json = "Channel hangup"
      end
      {"code"=>code, "id"=>channel_id, "message"=>json}
    end

    # Dials a channel id
    def channel_dial(channel_id)
      response = {"status"=>"", "code"=>"", "channel"=>channel_id, "message"=>""}
      response_client = @client.post("/ari/channels/#{channel_id}/dial")
      code = response_client.status_code
      response_body = response_client.body
      response["code"] = code.to_s
      if response_body == ""
        response["message"] = "Dialed"
      end
      
      while true
        message = JSON.parse(@channel_message.receive)
        if message["type"] == "Dial"
          # Handle Busy / Hangup status
          if message["peer"]["id"] == channel_id && message["dialstatus"] == "BUSY"
            response["status"] = "error"
            response["message"] = "Client didn't answer"
            break
          end

          # Handle Answer
          if message["peer"]["id"] == channel_id && message["dialstatus"] == "ANSWER"
            response["status"] = "OK"
            response["message"] = "Client answer"
            break
          end
        end
      end

      response
    end

    # Puts channel on hold
    def channel_moh(channel_id)
      response = @client.post("/ari/channels/#{channel_id}/moh")
      code = response.status_code
      json = response.body
      if json == ""
        json = "Music on Hold"
      end

      {"code"=>code,"message"=>json}
    end

    # Removes Music on hold from channel
    def channel_remove_moh(channel_id)
      response = @client.delete("/ari/channels/#{channel_id}/moh")
      code = response.status_code
      json = response.body
      if json == ""
        json = "Music on Hold Removed"
      end

      {"code"=>code,"message"=>json}
    end

    # Plays media on channel
    def channel_play(channel_id,media)
      response = @client.post("/ari/channels/#{channel_id}/play?media=#{media}")
      code = response.status_code
      json = response.body
      if code = 201
        json = "Media #{media} was queued"
      end

      {"code"=>code,"message"=>json}
    end

    # Add channel to bridge
    def bridge_add_channel(bridge_id,channel_id)
      response = @client.post("/ari/bridges/#{bridge_id}/addChannel?channel=#{channel_id}")
      code = response.status_code
      json = response.body
      if json == ""
        json = "Channel added to Bridge"
      end

      {"code"=>code,"message"=>json}
    end

    def start_websocket
      spawn do
        # Run websocket to get events from Asterisk
        ws_asterisk = HTTP::WebSocket.new(URI.parse("#{@websocket_host}/ari/events?api_key=#{@username}:#{@secret}&app=#{@ari_app}"))
        ws_asterisk.on_message do |message|
          @channel_message.send message
          # puts "============================================= Websocket Message ================================================="
          # puts message
        end
        ws_asterisk.run
      end
    end

    def disconnect
      @client.close
    end

  end
end