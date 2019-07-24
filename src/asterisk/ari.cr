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

    def initialize(@host = "http://localhost:8088", @username = "", @secret = "")
      uri = URI.parse(@host)
      @client = HTTP::Client.new(uri)
      @client.basic_auth(@username,@secret)
    end

    def block(&block)
      block
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

    # Hangup a channel id
    def channel_hangup(channel_id)
      response = @client.delete("/ari/channels/#{channel_id}")
      code = response.status_code
      json = response.body
      if json == ""
        json = "Hangup"
      end
      {"code"=>code, "id"=>channel_id, "message"=>json}
    end

    # Dials a channel id
    def channel_dial(channel_id)
      response = @client.post("/ari/channels/#{channel_id}/dial")
      code = response.status_code
      json = response.body
      if json == ""
        json = "Dialed"
      end
      {"code"=>code, "id"=>channel_id, "message"=>json}
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

    def disconnect
      @client.close
    end

  end
end