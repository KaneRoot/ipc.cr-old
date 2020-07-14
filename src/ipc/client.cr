
class IPC::Client < IPC::Context
	property server_fd : Int32?

	# By default, this is a client.
	def initialize(service_name : String)
		super()
		serverfd = 0

		r = LibIPC.ipc_connection(self.pointer, service_name, pointerof(serverfd))
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "error during connection establishment: #{m}"
		end

		@server_fd = serverfd

		# Very important as there are filesystem side-effects.
		at_exit { close }
	end

	def read
		unless (fd = @server_fd).nil?
			message = LibIPC::Message.new
			r = LibIPC.ipc_read_fd(fd, pointerof(message))
			if r.error_code != 0
				m = String.new r.error_message.to_slice
				raise Exception.new "error reading a message: #{m}"
			end
			IPC::Message.new pointerof(message)
		else
			raise "Client not connected to a server"
		end
	end
end
