require "./lowlevel"

class IPC::Message
	getter mtype : UInt8   # libipc message type
	property type : UInt8    # libipc user message type
	property payload : Bytes

	def initialize(message : Pointer(LibIPC::Message))
		if message.null?
			@mtype = LibIPC::MessageType::Error.to_u8
			@type = 0
			@payload = Bytes.new "".to_unsafe, 0
		else
			m = message.value
			@mtype = m.type
			@type = m.user_type
			@payload = Bytes.new m.payload, m.length
		end
	end

	def initialize(message : LibIPC::Message)
		initialize pointerof(message)
	end

	def initialize(mtype, type, payload : Bytes)
		@mtype = mtype.to_u8
		@type = type
		@payload = payload
	end

	def initialize(mtype, type, payload : String)
		initialize(mtype, type, Bytes.new(payload.to_unsafe, payload.bytesize))
	end

	def to_s
		"(internal) type #{@mtype}, (user) type #{@type}, payload #{String.new @payload}"
	end

end

