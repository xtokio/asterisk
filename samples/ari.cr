require "../src/asterisk.cr"

host = "http://localhost:8088"
websocket_host = "ws://localhost:8088"
ari_app = "ari_app"
username = "admin"
secret = "supersecret"

# Setup server login information
Asterisk.credentials(host,websocket_host,ari_app,username,secret)
bridge_id = "1dfcdfe8c8ef74c8"
channel_id = "1564268877.529"

channel_available = Asterisk.channel_available(bridge_id,channel_id)
puts "#{channel_available["status"]} - #{channel_available["message"]}"
if channel_available["status"] == "OK"
  add_channel = Asterisk.add_channel_to_bridge("SIP/101",bridge_id)
  puts add_channel
  # puts "New channel added: #{add_channel["channel"]}"
end

phone_login = Asterisk.phone_login("SIP/101")
puts phone_login