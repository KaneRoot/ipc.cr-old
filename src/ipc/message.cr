require "json"

# JSON is currently used for messages over websockets
# At some point, this will be replaced by the CBOR format

class IPC::Message
	property fd      : Int32   # file descriptor
	property mtype   : UInt8   # libipc message type
	property utype   : UInt8   # libipc user message type
	property payload : Bytes

	struct JSONMessage
		include JSON::Serializable

		property mtype : UInt8 = 1  # libipc message type
		property utype : UInt8      # libipc user message type
		property payload : String

		def initialize(@utype, @payload, @mtype = 1)
		end
	end

	def self.from_json (str : String)
		jsonmessage = JSONMessage.from_json str

		IPC::Message.new 0, jsonmessage.mtype, jsonmessage.utype, jsonmessage.payload
	end

	def to_json
		JSONMessage.new(@utype, String.new(@payload), @mtype).to_json
	end

	def initialize(message : Pointer(LibIPC::Message))
		if message.null?
			@mtype = LibIPC::MessageType::Error.to_u8
			@fd = 0
			@utype = 0
			@payload = Bytes.new "".to_unsafe, 0
		else
			m = message.value
			@fd = m.fd
			@mtype = m.type
			@utype = m.user_type
			@payload = Bytes.new m.payload, m.length
		end
	end

	def initialize(message : LibIPC::Message)
		initialize pointerof(message)
	end

	def initialize(@fd, mtype, @utype, @payload : Bytes)
		@mtype = mtype.to_u8
	end

	def initialize(fd, mtype, utype, payload : String)
		initialize(fd, mtype, utype, Bytes.new(payload.to_unsafe, payload.bytesize))
	end

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

	def to_packet
		IPC::Message.to_packet @utype, String.new(@payload)
	end

	def copy_to_message_pointer(pm : LibIPC::Message*)
		LibIPC.ipc_message_copy pm, @fd, @mtype, @utype, @payload, @payload.size
	end

	def to_s
		"(internal) utype #{@mtype}, (user) utype #{@utype}, payload #{String.new @payload}"
	end

end

