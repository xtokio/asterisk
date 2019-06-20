require "../src/asterisk.cr"

console = Asterisk::Console.new

# Get the call id for the given extension ( needs to be an active channel )
call_id = console.call_id("100")
puts call_id