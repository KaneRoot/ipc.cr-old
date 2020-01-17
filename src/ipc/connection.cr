require "./lowlevel"
require "./message"
require "./event"

class IPC::Connection
	getter connection : LibIPC::Connection
	getter closed = false

	# connection already established
	def initialize(c : LibIPC::Connection)
		@connection = c
	end

	def initialize(service_name : String)
		@connection = LibIPC::Connection.new

		r = LibIPC.ipc_connection(LibC.environ, self.pointer, service_name)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "error during connection establishment: #{m}"
		end
	end

	def initialize(name, &block)
		initialize(name)

		yield self

		close
	end

	# Adds a new connection based on the socket file descriptor
	def initialize(fd : Int32)
		external_connection = LibIPC::Connection.new
		external_connection.fd = fd
		initialize(external_connection)
	end

	# sanitizer
	def fd
		@connection.fd
	end

	def send(type : UInt8, payload : Bytes)
		message = LibIPC::Message.new type: LibIPC::MessageType::Data.to_u8, user_type: type, length: payload.bytesize, payload: payload.to_unsafe

		r = LibIPC.ipc_write(self.pointer, pointerof(message))
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "error writing a message: #{m}"
		end
	end

	def send(type : UInt8, payload : String)
		send(type, Bytes.new(payload.to_unsafe, payload.bytesize))
	end

	def send(message : IPC::Message)
		send(message.type, message.payload)
	end

	def read
		message = LibIPC::Message.new
		r = LibIPC.ipc_read(pointerof(@connection), pointerof(message))
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "error reading a message: #{m}"
		end

		IPC::Message.new pointerof(message)
	end

	def close
		return if @closed

		r = LibIPC.ipc_close(self.pointer)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "cannot correctly close the connection: #{m}"
		end

		@closed = true
	end

	def pointer
		pointerof(@connection)
	end

	def type
		@connection.type
	end
end

# This class is designed for stand alone connections, where the StandAloneConnection object
# should NOT be garbage collected (which means the end of the communication)
class IPC::StandAloneConnection
	# close the connection in case the object is garbage collected
	def finalize
		close
	end
end

class IPC::Connections
	property base_timer : Int64 = 0
	property timer : Int64 = 0
	getter connections : LibIPC::Connections

	def initialize
		@connections = LibIPC::Connections.new
	end

	def initialize(@connections : LibIPC::Connections)
	end

	def << (client : IPC::Connection)
		r = LibIPC.ipc_add(self.pointer, client.pointer)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "cannot add an arbitrary file descriptor: #{m}"
		end
	end

	def << (fd : Int)
		r = LibIPC.ipc_add_fd(self.pointer, fd)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "cannot add an arbitrary file descriptor: #{m}"
		end
	end

	def remove (client : IPC::Connection)
		c = client.connection
		r = LibIPC.ipc_del(self.pointer, pointerof(c))
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "cannot remove a client: #{m}"
		end
	end

	def remove_fd (fd : Int)
		r = LibIPC.ipc_del_fd(self.pointer, fd)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "cannot remove an arbitrary file descriptor: #{m}"
		end
	end

	def wait_event(server : IPC::Connection | Nil, &block) : Tuple(LibIPC::EventType, IPC::Message, IPC::Connection) | Tuple(LibIPC::EventType, Nil, Nil)
		event = LibIPC::Event.new

		serverp = nil
		unless server.nil?
			serverp = server.pointer
		end

		r = LibIPC.ipc_wait_event self.pointer, serverp, pointerof(event), pointerof(@timer)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			yield IPC::Exception.new "error waiting for a new event: #{m}"
		end

		eventtype = event.type.unsafe_as(LibIPC::EventType)

		# if event type is Timer, there is no connection nor message
		case eventtype
		when LibIPC::EventType::Timer
			return eventtype, nil, nil
		end

		connection = IPC::Connection.new event.origin.unsafe_as(Pointer(LibIPC::Connection)).value

		message = event.message.unsafe_as(Pointer(LibIPC::Message))

		return eventtype, IPC::Message.new(message), connection
	end

	def loop(server : IPC::Connection | IPC::Server | ::Nil, &block : Proc(IPC::Event::Events|Exception, Nil))
		if @base_timer > 0 && @timer == 0
			@timer = @base_timer
		end

		::loop do
			type, message, connection = wait_event server, &block

			case type
			when LibIPC::EventType::Timer
				# reset timer
				@timer = @base_timer
				yield IPC::Event::Timer.new
			when LibIPC::EventType::Connection
				yield IPC::Event::Connection.new connection.not_nil!

			when LibIPC::EventType::NotSet
				yield IPC::Exception.new "even type not set"

			when LibIPC::EventType::Error
				yield IPC::Exception.new "even type indicates an error"

			when LibIPC::EventType::ExtraSocket
				yield IPC::Event::ExtraSocket.new message.not_nil!, connection.not_nil!

			when LibIPC::EventType::Switch
				yield IPC::Event::Switch.new message.not_nil!, connection.not_nil!

			when LibIPC::EventType::Message
				yield IPC::Event::Message.new message.not_nil!, connection.not_nil!

			# for now, the libipc does not provide lookup events
			# networkd uses a simple LibIPC::EventType::Message
			# when LibIPC::EventType::LookUp
				# yield IPC::Event::LookUp.new message, connection

			when LibIPC::EventType::Disconnection
				yield IPC::Event::Disconnection.new connection.not_nil!
			end
		end
	end

	# sanitizer
	def pointer
		pointerof(@connections)
	end

	def pp
		LibIPC.ipc_connections_print @connections
	end
end
