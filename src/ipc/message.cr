require "./lowlevel"

class IPC::Message

	def self.to_packet (user_type : Int, message : String)
		payload = Bytes.new (6 + message.to_slice.size)

		# true start
		payload[0] = 1.to_u8
		IO::ByteFormat::NetworkEndian.encode message.to_slice.size, (payload + 1)

		# second part: user message
		payload[5] = user_type.to_u8
		(payload + 6).copy_from message.to_slice

		return payload
	end

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

	def to_packet
		IPC::Message.to_packet @type, String.new(@payload)
	end

	def to_s
		"(internal) type #{@mtype}, (user) type #{@type}, payload #{String.new @payload}"
	end

end

