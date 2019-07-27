require "./lowlevel"

class IPC::Switch
	@switch = LibIPC::Switchings.new

	def inilialize
	end

	def add (fd1 : Int32, fd2 : Int32)
		LibIPC.ipc_switching_add self.pointer, fd1, fd2
	end

	def del (fd : Int32)
		LibIPC.ipc_switching_del self.pointer, fd
	end

	def close
		LibIPC.ipc_switching_free self.pointer
	end

	def print
		LibIPC.ipc_switching_print self.pointer
	end

	def finalize
		close
	end

	# sanitizer
	def pointer
		pointerof(@switch)
	end
end
