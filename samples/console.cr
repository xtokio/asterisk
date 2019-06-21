require "../src/asterisk.cr"

# Get the call id for the given extension ( needs to be an active channel )
call_id = Asterisk.call_id("100")
puts call_id