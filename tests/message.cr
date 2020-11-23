
# Context class, so the variables are available everywhere.
class Context
	class_property requests  = [] of IPC::CBOR.class
	class_property responses = [] of IPC::CBOR.class
end

class IPC::CBOR
	def handle
		raise "unimplemented"
	end
end

IPC::CBOR.message Message, 10 do
	property content     : String?
	property some_number : Int32?
	def initialize(@content = nil, @some_number = nil)
	end

	def handle
		info "message received: #{@content}, number: #{@some_number}"
		if number = @some_number
			::MessageReceived.new number - 1
		else
			::MessageReceived.new
		end
	end
end
Context.requests << Message


IPC::CBOR.message Error, 0 do
	property reason : String
	def initialize(@reason)
	end
end
Context.responses << Error

IPC::CBOR.message MessageReceived, 20 do
	property minus_one : Int32?
	def initialize(@minus_one = nil)
	end

	def handle
		info "<< MessageReceived (#{@minus_one})"
	end
end
Context.responses << MessageReceived
