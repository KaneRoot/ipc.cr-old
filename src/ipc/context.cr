
class IPC::Context
	property base_timer : Int32 = LibIPC::INFTIM
	property timer      : Int32 = LibIPC::INFTIM
	getter context      : LibIPC::Ctx

	def initialize
		@context = LibIPC::Ctx.new
	end

	def initialize(@context : LibIPC::Ctx)
	end

	def initialize(name : String, &block : Proc(IPC::Event::Events|Exception, Nil))
		initialize name
		::loop &block
		close
	end

	def << (fd : Int)
		r = LibIPC.ipc_add_fd(self.pointer, fd)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "cannot add an arbitrary file descriptor: #{m}"
		end
	end

	def remove_index (index : UInt32)
		r = LibIPC.ipc_del(self.pointer, index)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "cannot remove an arbitrary file descriptor: #{m}"
		end
	end
	def remove_fd (fd : Int32)
		r = LibIPC.ipc_del_fd(self.pointer, fd)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "cannot remove an arbitrary file descriptor: #{m}"
		end
	end

	def wait_event(&block) : IPC::Event::Events | Exception
		event = LibIPC::Event.new

		r = LibIPC.ipc_wait_event self.pointer, pointerof(event), pointerof(@timer)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			yield IPC::Exception.new "error waiting for a new event: #{m}"
		end

		eventtype = event.type.unsafe_as(LibIPC::EventType)

		# if event type is Timer, there is no connection nor message
		case eventtype
		when LibIPC::EventType::NotSet
			return Exception.new "'Event type: not set"
		when LibIPC::EventType::Error
			return IPC::Event::Error.new event.origin, event.index
		when LibIPC::EventType::ExtraSocket   # Message received from a non IPC socket.
			return IPC::Event::ExtraSocket.new event.origin, event.index
		when LibIPC::EventType::Switch        # Message to send to a corresponding fd.
			return IPC::Event::Switch.new event.origin, event.index
		when LibIPC::EventType::Connection    # New user.
			return IPC::Event::Connection.new event.origin, event.index
		when LibIPC::EventType::Disconnection # User disconnected.
			return IPC::Event::Disconnection.new event.origin, event.index
		when LibIPC::EventType::Message       # New message.
			lowlevel_message = event.message.unsafe_as(Pointer(LibIPC::Message))
			ipc_message = IPC::Message.new lowlevel_message
			return IPC::Event::MessageReceived.new event.origin, event.index, ipc_message
		when LibIPC::EventType::LookUp        # Client asking for a service through ipcd.
			# for now, the libipc does not provide lookup events
			# ipcd uses a simple LibIPC::EventType::Message
			return IPC::Event::LookUp.new event.origin, event.index
		when LibIPC::EventType::Timer         # Timeout in the poll(2) function.
			return IPC::Event::Timer.new
		when LibIPC::EventType::Tx            # Message sent.
			return IPC::Event::MessageSent.new event.origin, event.index
		end

		return Exception.new "Cannot understand the event type: #{eventtype}"
	end

	def loop(&block : Proc(IPC::Event::Events|Exception, Nil))
		::loop do
			if @base_timer > 0 && @timer == 0
				@timer = @base_timer
			end

			yield wait_event &block
		end
	end

	def send(fd : Int32, utype : UInt8, payload : Bytes)
		message = LibIPC::Message.new fd: fd,
			type: LibIPC::MessageType::Data.to_u8,
			user_type: utype,
			length: payload.bytesize,
			payload: payload.to_unsafe

		r = LibIPC.ipc_write(self.pointer, pointerof(message))
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "error writing a message: #{m}"
		end
	end

	def send(fd : Int32, utype : UInt8, payload : String)
		send(fd, utype, Bytes.new(payload.to_unsafe, payload.bytesize))
	end

	def send(fd : Int32, message : IPC::Message)
		send(fd, message.fd, message.utype, message.payload)
	end

	def read(index : UInt32)
		message = LibIPC::Message.new
		r = LibIPC.ipc_read(self.pointer, index, pointerof(message))
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "error reading a message: #{m}"
		end

		IPC::Message.new pointerof(message)
	end

	# sanitizer
	def pointer
		pointerof(@context)
	end

	# sanitizer
	def fd
		@connection.fd
	end

	def close
		return if @closed
		r = LibIPC.ipc_close_all(self.pointer)
		if r.error_code != 0
			m = String.new r.error_message.to_slice
			raise Exception.new "cannot correctly close the connection: #{m}"
		end
		LibIPC.ipc_ctx_free(self.pointer)
		@closed = true
	end

	def pp
		LibIPC.ipc_ctx_print self.pointer
	end
end
