require "../src/asterisk.cr"

host = ENV["ASTERISKCR_ARI_HOST"]
events_url = ASTERISKCR_ARI_EVENTS_URL
ari_app = ASTERISKCR_ARI_APP 
username = ENV["ASTERISKCR_ARI_USERNAME"]
secret = ENV["ASTERISKCR_ARI_SECRET"]

events = Asterisk::ARIEvents.new(host,events_url,username,secret,ari_app)

ari = Asterisk::ARI.new(host, username, secret)

# Creates a new bridge
bridge_new = ari.bridge_new
puts bridge_new

# Creates a new channel
channel_new = ari.channel_new("SIP/100","ari_app")
puts channel_new
puts channel_new["id"]

# Dials that channel
channel_dial = ari.channel_dial(channel_new["id"])
puts channel_dial

# Adds channel to bridge
puts "Bridge ID #{bridge_new["id"]} / Channel ID #{channel_new["id"]}"
channel_to_bridge = ari.bridge_add_channel(bridge_new["id"],channel_new["id"])
puts channel_to_bridge

# Example block to execute on an Event change
param_moh = ari.block do
  channel_moh = ari.channel_moh(channel_new["id"])
  puts channel_moh
end

ari.disconnect

# Listen for specific event to act upon executing custom block code
events.register("ChannelStateChange","channel",channel_new["id"],"Up",&param_moh)

sleep