
class IPC::Client < IPC::Context
	# By default, this is a client.
	def initialize(service_name : String)
		super()
		r = LibIPC.ipc_connection(self.pointer, service_name)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "error during connection establishment: #{m}"
		end

		# Very important as there are filesystem side-effects.
		at_exit { close }
	end
end
