require "cbor"

require "./ipc.cr"

class IPC::CBOR
	include ::CBOR::Serializable

	@[::CBOR::Field(ignored: true)]
	getter       type = -1
	class_getter type = -1

	property     id   : ::CBOR::Any?

	macro message(id, type, &block)
		class {{id}} < ::IPC::CBOR
			include ::CBOR::Serializable

			@@type = {{type}}
			def type
				@@type
			end

			{{yield}}
		end
	end
end

class IPC::Context
	def send(fd : Int32, message : IPC::CBOR)
		send fd, message.type.to_u8, message.to_cbor
	end
	def send_now(fd : Int32, message : IPC::CBOR)
		send_now fd, message.type.to_u8, message.to_cbor
	end
end

class IPC::Client
	def send(message : IPC::CBOR)
		send @server_fd.not_nil!, message.type.to_u8, message.to_cbor
	end
	def send_now(message : IPC::CBOR)
		send_now @server_fd.not_nil!, message.type.to_u8, message.to_cbor
	end
end

# CAUTION: Only use this method on an Array(IPC::CBOR.class)
class Array(T)
	def parse_ipc_cbor(message : IPC::Message) : IPC::CBOR?
		message_type = find &.type.==(message.utype)

		if message_type.nil?
			raise "invalid message type (#{message.utype})"
		end

		message_type.from_cbor message.payload
	end
end

