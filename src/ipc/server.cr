
# the server is a client with a different init function
# ipc_connection => ipc_server_init
class IPC::Server < IPC::Context
	def initialize(name : String)
		initialize()
		r = LibIPC.ipc_server_init(self.pointer, name)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "cannot initialize the server named #{name}: #{m}"
		end

		# Very important as there are filesystem side-effects.
		# FIXME: for now, let's forget that.
		# at_exit { close }
	end
end

# TODO: replacing IPC::Service by the IPC::NetworkD class?
class IPC::SwitchingService < IPC::Server
	property switch = IPC::Switch.new

	# automatic removal of the fd in the switching list
	def remove_fd (fd : Int)
		super
		@switch.del fd
	end
end

