# TODO: Write documentation for `Asterisk`
require "./asterisk/*"

module Asterisk
  extend self

  def call_conference(connection,channel,conference_number)
    ami = connect(connection)
    ami.connect!
    events = ami.send_action({"Action" => "Originate","Channel" => channel,"Timeout" => "30000", "CallerID" => "Asterisk", "Application" => "ConfBridge", "Async" => "true", "Data" => conference_number})
    
    events
  end

  def conference_list(connection,conference_number)
    ami = connect(connection)
    ami.connect!
    events = ami.send_action({"Action" => "ConfbridgeList","Conference" => conference_number},"ConfbridgeListComplete")
    
    status = {"status" => "Inactive", "list" => "0"}
    if events["events"]["listitems"]?
      status["status"] = "Active"
      status["list"] = events["events"]["listitems"]
    end

    status
  end

  def mute(connection,channel,conference_number)
    ami = connect(connection)
    ami.connect!
    events = ami.send_action({"Action" => "ConfbridgeMute","Conference" => conference_number,"Channel" => channel})
    
    events
  end

  def unmute(connection,channel,conference_number)
    ami = connect(connection)
    ami.connect!
    events = ami.send_action({"Action" => "ConfbridgeUnmute","Conference" => conference_number,"Channel" => channel})
    
    events
  end

  def hangup(connection,channel)
    ami = connect(connection)
    ami.connect!
    events = ami.send_action({"Action" => "Hangup","Channel" => channel})

    events
  end

  def extension_state(connection,extension)
    ami = connect(connection)
    ami.connect!
    events = ami.send_action({"Action" => "ExtensionState","Exten" => extension},"PeerStatus")

    status = {"status" => "Inactive", "channel" => ""}
    if events["events"]["channel"]?
      status = {"status" => "Active", "channel" => events["events"]["channel"]}
    end

    status
  end

  def channel_status(connection,channel)
    ami = connect(connection)
    ami.connect!
    events = ami.send_action({"Action" => "Status","Channel" => channel},"StatusComplete")
    
    events
  end

  def sip_peers(connection)
    ami = connect(connection)
    ami.connect!
    events = ami.send_action({"Action" => "SIPpeers"},"PeerlistComplete")
    
    events
  end

  def active_call(extension)
    command_call_id = "asterisk -rx\"sip show channels\" | grep '#{extension}' -w | awk 'NR==1{print $3}'"
    call_id = execute_command(command_call_id)
    # Validate if not empty
    command_channel = "asterisk -rx\"sip show channel #{call_id}\" | grep 'Owner channel ID:' -w | awk '{print $4}'"
    channel = execute_command(command_channel)
    # Validate if not empty
    {"status"=>"OK","call_id"=>call_id,"channel"=>channel}
  end

  private def execute_command(command)
    io = IO::Memory.new 
    Process.run(command, shell: true, output: io)
    io.to_s
  end

  private def connect(connection)
    host = connection["host"]
    port = connection["port"]
    username = connection["username"]
    secret = connection["secret"]

    Asterisk::AMI.new(host, port, username, secret)
  end

end