module Asterisk
  class Console

    def call_id(exten)
      command = "asterisk -rx \"sip show channels\" | awk '{print \"|\"$2\"|\" $3}' | head | grep #{exten} | sed 's/|#{exten}|//g'"
      execute_command(command)
    end

    private def execute_command(command)
      io = IO::Memory.new 
      Process.run(command, shell: true, output: io)
      io.to_s
    end

  end

end