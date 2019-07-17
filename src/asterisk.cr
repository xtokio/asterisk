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
    events = ami.send_action({"Action" => "ExtensionState","Exten" => extension})

    status = {"status" => "Inactive", "channel" => ""}
    if events["events"]["channel"]?
      status = {"status" => "Active", "channel" => events["events"]["channel"]}
    end

    status
  end

  def channel_status(connection,channel)
    ami = connect(connection)
    ami.connect!
    events = ami.send_action({"Action" => "Status","Channel" => channel})
    
    events
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