require "./lowlevel"
require "./message"
require "./event"
require "./connection"

# the server is a connection with two different function calls
# ipc_connection => ipc_server_init
# ipc_close      => ipc_server_close
class IPC::Server < IPC::Connection
	def initialize(name : String)
		@connection = LibIPC::Connection.new
		r = LibIPC.ipc_server_init(LibC.environ, self.pointer, name)
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
			raise Exception.new "cannot initialize the server named #{name}: #{m}"
		end

		# Very important as there are filesystem side-effects.
		at_exit { close }
	end

	def close
		return if @closed

		r = LibIPC.ipc_server_close(self.pointer)
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
			raise Exception.new "cannot close the server correctly: #{m}"
		end

		@closed = true
	end
end

class IPC::Service < IPC::Connections
	@service_info : IPC::Server

	def initialize(name : String)
		@service_info = IPC::Server.new name
		super()
	end

	def initialize(name : String, &block : Proc(Events|Exception, Nil))
		initialize name
		loop &block
		close
	end

	# sanitizer
	def fd
		@service_info.fd
	end

	def loop(&block : Proc(Events|Exception, Nil))
		super(@service_info, &block)
	end

	def close
		@service_info.close
	end
end

# TODO: replacing IPC::Service by the IPC::NetworkD class?
class IPC::SwitchingService < IPC::Service
	property switch = IPC::Switch.new

	# automatic removal of the fd in the switching list
	def remove_fd (fd : Int)
		super
		@switch.del fd
	end

	def wait_event(server : IPC::Connection , &block) : Tuple(LibIPC::EventType, IPC::Message, IPC::Connection)
		event = LibIPC::Event.new

		serverp = server.pointer
		r = LibIPC.ipc_wait_event_networkd self.pointer, serverp, pointerof(event), @switch.pointer
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
			yield IPC::Exception.new "error waiting for a new event: #{m}"
		end

		connection = IPC::Connection.new event.origin.unsafe_as(Pointer(LibIPC::Connection)).value

		message = event.message.unsafe_as(Pointer(LibIPC::Message))

		eventtype = event.type.unsafe_as(LibIPC::EventType)

		return eventtype, IPC::Message.new(message), connection
	end
end

