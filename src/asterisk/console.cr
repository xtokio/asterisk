module Asterisk
  extend self

    def make_call(connection,channel,conference_number)
      host = connection["host"]
      port = connection["port"]
      username = connection["username"]
      secret = connection["secret"]

      ami = Asterisk::AMI.new(host, port, username, secret)
      ami.connect!
      ami.send_action({"Action" => "Originate","Channel" => channel,"Timeout" => "30000", "CallerID" => "Asterisk", "Application" => "ConfBridge", "Async" => "true", "Data" => conference_number})
      ami.disconnect!
    end

    def get_call_id(exten)
      command = "asterisk -rx \"sip show channels\" | awk '{print \"|\"$2\"|\" $3}' | head | grep #{exten} | sed 's/|#{exten}|//g'"
      execute_command(command)
    end

    def get_channel_details(call_id)
      command = "asterisk -rx \"sip show channel #{call_id}\""
      execute_command(command)
    end

    def active_call?(exten)
      active = false
      call_id = get_call_id(exten)
      if call_id.blank?
        active = false
      else
        channel_details = get_channel_details(call_id)
        channel = channel_details.split("\n")
        channel.each do |line|
          if line.split(":").first.strip == "Owner channel ID"
            if line.split(":").last.strip[0] == '<'
              active = false
            else
              active = true
            end
          end
        end
      end
      active      
    end

    private def execute_command(command)
      io = IO::Memory.new 
      Process.run(command, shell: true, output: io)
      io.to_s
    end

end