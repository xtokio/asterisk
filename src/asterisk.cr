# TODO: Write documentation for `Asterisk`
require "./asterisk/*"

module Asterisk
  extend self
  @@host = ""
  @@websocket_host = ""
  @@ari_app = ""
  @@username = ""
  @@secret = ""

  def credentials(param_host="",param_websocket_host="",param_ari_app="",param_username="",param_secret="")
    @@host = param_host
    @@websocket_host = param_websocket_host
    @@ari_app = param_ari_app
    @@username = param_username
    @@secret = param_secret
  end

  def channel_available(bridge_id,channel_id)
    response = {"status"=>"OK","message"=>""}
    ari = connect()
    bridge_details = ari.bridge_details(bridge_id)
    bridge_details = JSON.parse(bridge_details.to_json)
    if bridge_details["message"]?
      response["status"] = "error" 
      response["message"] = bridge_details["message"].to_s
    else
      channel_details = ari.channel_details(channel_id)
      channel_details = JSON.parse(channel_details.to_json)
      if channel_details["message"]?
        response["status"] = "error" 
        response["message"] = channel_details["message"].to_s
      else
        if channel_details["state"] == "Up" && bridge_details["channels"].size == 1
          response["message"] = "Channel is available"
        else
          response["status"] = "error" 
          response["message"] = "Channel is unavailable"
        end
      end
    end
    ari.disconnect()
    response
  end

  def add_channel_to_bridge(exten,bridge_id)
    response = {"status"=>"","channel"=>"", "message"=>""}
    ari = connect()
    # Creates a new channel
    channel_new = ari.channel_new(exten,"ari_app")
    response["channel"] = channel_new["id"].to_s

    # Dials that channel
    channel_dial = ari.channel_dial(channel_new["id"])
    response["status"] = channel_dial["status"].to_s
    response["message"] = channel_dial["message"].to_s

    if channel_dial["status"] == "OK"
      # Adds channel to bridge
      channel_to_bridge = ari.bridge_add_channel(bridge_id,channel_new["id"])
    end

    ari.disconnect()

    response
  end

  def phone_login(exten)
    response = {"status"=>"", "bridge"=>"", "channel"=>"", "message"=>""}
    ari = connect()
    # Creates a new bridge
    bridge_new = ari.bridge_new
    response["bridge"] = bridge_new["id"]
    
    # Creates a new channel
    channel_new = ari.channel_new(exten,"ari_app")
    response["channel"] = channel_new["id"].to_s

    # Dials that channel
    channel_dial = ari.channel_dial(channel_new["id"])
    response["status"] = channel_dial["status"].to_s
    response["message"] = channel_dial["message"].to_s

    if channel_dial["status"] == "OK"
      # Adds channel to bridge
      channel_to_bridge = ari.bridge_add_channel(bridge_new["id"],channel_new["id"])
    end

    ari.disconnect()
    response
  end

  def connect
    Asterisk::ARI.new(@@host,@@websocket_host,@@ari_app,@@username,@@secret)
  end

end