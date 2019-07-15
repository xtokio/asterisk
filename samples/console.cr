require "../src/asterisk.cr"

host = ""
port = ""
username = ""
secret = ""

connection = {"host" => host, "port" => port, "username" => username, "secret" => secret}
channel_100 = "SIP/100"
channel_101 = "SIP/101"
conference_number = "100"
Asterisk.make_call(connection,channel_100,conference_number)
Asterisk.make_call(connection,channel_101,conference_number)

# Get the call id for the given extension ( needs to be an active channel )
# call_id = Asterisk.call_id("100")
# puts call_id