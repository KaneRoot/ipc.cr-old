
class IPC::Client < IPC::Context
	property server_fd : Int32

	# By default, this is a client.
	def initialize(service_name : String)
		super()
		serverfd = 0

		r = LibIPC.ipc_connection(self.pointer, service_name, pointerof(serverfd))
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "error during connection establishment: #{m}"
		end

		@server_fd = server_fd

		# Very important as there are filesystem side-effects.
		at_exit { close }
	end
end
