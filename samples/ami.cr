require "../src/asterisk.cr"

host = ENV["ASTERISKCR_AMI_HOST"]
port = ENV["ASTERISKCR_AMI_PORT"]
username = ENV["ASTERISKCR_AMI_USERNAME"]
secret = ENV["ASTERISKCR_AMI_SECRET"]

connection = {"host" => host, "port" => port, "username" => username, "secret" => secret}

channel_100 = "SIP/100"
channel_101 = "SIP/101"
conference_number = "100"
extension = "101"

events_channel_100 = Asterisk.call_conference(connection,channel_100,conference_number)
events_channel_101 = Asterisk.call_conference(connection,channel_101,conference_number)

# gets channel id
channel = events_channel_101["events"]["channel"]

sleep 5
channel_state = Asterisk.extension_state(connection,extension)
puts channel_state

channel_status = Asterisk.channel_status(connection,channel)
puts channel_status

puts "############# Call Starts! #######################"

sleep 10
Asterisk.mute(connection,channel,conference_number)
puts "Mute"

sleep 10
Asterisk.unmute(connection,channel,conference_number)
puts "UnMute"

puts "############# Call After disconnect! #######################"