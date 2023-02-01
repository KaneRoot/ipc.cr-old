require "json"

require "./ipc.cr"

class IPC::JSON
	include ::JSON::Serializable

	#@[::JSON::Field(ignored: true)]
	class_property type = -1

	property     id   : ::JSON::Any?

	def type
		@@type
	end

	macro message(id, type, &block)
		class {{id}} < ::IPC::JSON
			include ::JSON::Serializable

			@@type = {{type}}

			{{yield}}
		end
	end
end

class IPC::Context
	def send(fd : Int32, message : IPC::JSON)
		send fd, message.type.to_u8, message.to_json
	end
	def send_now(fd : Int32, message : IPC::JSON)
		send_now fd, message.type.to_u8, message.to_json
	end
end

class IPC::Client
	def send(message : IPC::JSON)
		send @server_fd.not_nil!, message.type.to_u8, message.to_json
	end
	def send_now(message : IPC::JSON)
		send_now @server_fd.not_nil!, message.type.to_u8, message.to_json
	end
end

# CAUTION: Only use this method on an Array(IPC::JSON.class)
class Array(T)
	def parse_ipc_json(message : IPC::Message) : IPC::JSON?
		message_type = find &.type.==(message.utype)

		payload = String.new message.payload

		if message_type.nil?
			raise "invalid message type (#{message.utype})"
		end

		message_type.from_json payload
	end
end

