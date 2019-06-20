require "../src/asterisk.cr"

host = "192.168.56.101"
port = "5038"
username = "admin"
secret = "V88Tig1"
reconnect = false

puts "############# Call Starts! #######################"
ami = Asterisk::AMI.new(host, port, username, secret, reconnect)
ami.connect!

# puts ami.send_action({"action" => "ListCommands"})
# puts ami.send_action({"action" => "SIPpeers"})
# puts ami.send_action({"action" => "Command", "command" => "agi show commands"})

# ami.send_action({"Action" => "Originate","Channel" => "SIP/100","Context" => "ConferenceRooms", "Exten" => "666", "Priority" => "1", "Variable" => "numberToDial=virtualbox/100"})

# Action: Originate
# ActionID: CreateConf
# Channel: SIP/1000
# Timeout: 30000
# CallerID: Asterisk
# Application: ConfBridge
# Async: true
# Data: 1234

ami.send_action({"Action" => "Originate","Channel" => "SIP/100","Timeout" => "30000", "CallerID" => "Asterisk", "Application" => "ConfBridge", "Async" => "true", "Data" => "1234"})
# puts ami.call_id("100")

ami.disconnect!
puts "############# Call After disconnect! #######################"

