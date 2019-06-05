# TODO: more typing stuff.
# Functions return enum error not just int, for instance.

@[Link("ipc")]
lib LibIPC
	struct Connection
		version :  LibC::UInt
		index :    LibC::UInt
		fd :       LibC::Int
		type :     UInt8
		spath :    LibC::Char* # [4096] # [PATH_MAX]
	end

	struct Connections
		cinfos :   Connection**
		size :     LibC::Int
	end

	enum Errors
		None = 0
		NotEnoughMemory
		ClosedRecipient
		ServerInitNoEnvironmentParam
		ServerInitNoServiceParam
		ServerInitNoServerNameParam
		ServerInitMalloc
		ConnectionNoServer
		ConnectionNoServiceName
		ConnectionNoEnvironmentParam
		ConnectionGenNoCinfo
		AcceptNoServiceParam
		AcceptNoClientParam
		Accept
		HandleNewConnectionNoCinfoParam
		HandleNewConnectionNoCinfosParam
		WaitEventSelect
		WaitEventNoClientsParam
		WaitEventNoEventParam
		HandleNewConnectionMalloc
		AddEmptyList
		AddNoParamClients
		AddNoParamClient
		AddFdNoParamCinfos
		DelEmptyList
		DelEmptiedList
		DelCannotFindClient
		DelNoClientsParam
		DelNoClientParam
		UsockSend
		UsockConnectSocket
		UsockConnectWrongFileDescriptor
		UsockConnectEmptyPath
		UsockClose
		UsockRemoveUnlink
		UsockRemoveNoFile
		UsockInitEmptyFileDescriptor
		UsockInitWrongFileDescriptor
		UsockInitEmptyPath
		UsockInitBind
		UsockInitListen
		UsockAcceptPathFileDescriptor
		UsockAccept
		UsockRecvNoBuffer
		UsockRecvNoLength
		UsockRecv
		MessageNewNoMessageParam
		MessageReadNomessageparam
		MessageWriteNoMessageParam
		MessageWriteNotEnoughData
		MessageFormatNoMessageParam
		MessageFormatInconsistentParams
		MessageFormatLength
		MessageFormatWriteEmptyMessage
		MessageFormatWriteEmptyMsize
		MessageFormatWriteEmptyBuffer
		MessageFormatReadEmptyMessage
		MessageFormatReadEmptyBuffer
		MessageFormatReadMessageSize
		MessageEmptyEmptyMessageList
	end

	enum MessageType
		ServerClose
		Error
		Data
	end

	struct Message
		type :       UInt8
		user_type :  UInt8
		length :     LibC::UInt
		payload :    LibC::Char*
	end

	enum EventType
		NotSet
		Error
		ExtraSocket
		Connection
		Disconnection
		Message
	end

	struct Event
		type :     EventType
		origin :   Connection*
		message :  Message*
	end

	fun ipc_server_init(env : LibC::Char**, connection : Connection*, sname : LibC::Char*) : LibC::Int
	fun ipc_server_close(Connection*) : LibC::Int
	fun ipc_close(Connection*) : LibC::Int

	# connection to a service
	fun ipc_connection(LibC::Char**, Connection*, LibC::Char*) : LibC::Int

	fun ipc_read(Connection*, Message*) : LibC::Int
	fun ipc_write(Connection*, Message*) : LibC::Int

	fun ipc_wait_event(Connections*, Connection*, Event*) : LibC::Int

	fun ipc_add(Connections*, Connection*) : LibC::Int
	fun ipc_del(Connections*, Connection*) : LibC::Int
	fun ipc_add_fd (Connections*, LibC::Int) : LibC::Int

	fun ipc_connection_copy(Connection*) : Connection*
	fun ipc_connection_eq(Connection*, Connection*) : LibC::Int

	fun ipc_connection_gen(Connection*, LibC::UInt, LibC::UInt)

	fun ipc_connections_free(Connections*)
	fun ipc_get(Connections*)
	fun ipc_errors_get (LibC::Int) : LibC::Char*
end

class IPC::Exception < ::Exception
end

class IPC::Message
	getter mtype : UInt8   # libipc message type
	getter type : UInt8    # libipc user message type
	getter payload : Bytes

	def initialize(message : Pointer(LibIPC::Message))
		if message.null?
			@mtype = LibIPC::MessageType::Error.to_u8
			@type = 0
			@payload = Bytes.new "".to_unsafe, 0
		else
			m = message.value
			@mtype = m.type
			@type = m.user_type
			@payload = Bytes.new m.payload, m.length
		end
	end

	def initialize(mtype, type, payload : Bytes)
		@mtype = mtype.to_u8
		@type = type
		@payload = payload
	end

	def initialize(mtype, type, payload : String)
		initialize(mtype, type, Bytes.new(payload.to_unsafe, payload.bytesize))
	end
end

class IPC::Event
	class Connection
		getter connection : IPC::Connection
		def initialize(@connection)
		end
	end

	class Disconnection
		getter connection : IPC::Connection
		def initialize(@connection)
		end
	end

	class Message
		getter message : ::IPC::Message
		getter connection : IPC::Connection
		def initialize(@message, @connection)
		end
	end

	class ExtraSocket < IPC::Event::Message
	end
end

class IPC::Connection
	getter connection : LibIPC::Connection
	getter closed = false

	# connection already established
	def initialize(c : LibIPC::Connection)
		@connection = c
	end

	def initialize(service_name : String)
		@connection = LibIPC::Connection.new
		r = LibIPC.ipc_connection(LibC.environ, pointerof(@connection), service_name)
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
			raise Exception.new "error during connection establishment: #{m}"
		end
	end

	def initialize(name, &block)
		initialize(name)

		yield self

		close
	end

	def send(type : UInt8, payload : Bytes)
		message = LibIPC::Message.new type: LibIPC::MessageType::Data.to_u8, user_type: type, length: payload.bytesize, payload: payload.to_unsafe

		r = LibIPC.ipc_write(pointerof(@connection), pointerof(message))
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
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
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
			raise Exception.new "error reading a message: #{m}"
		end

		IPC::Message.new message.mtype, message.type, message.payload
	end

	def close
		return if @closed

		r = LibIPC.ipc_close(pointerof(@connection))
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
			raise Exception.new "cannot correctly close the connection: #{m}"
		end

		@closed = true
	end
end

alias Events = IPC::Event::Connection | IPC::Event::Disconnection | IPC::Event::Message | IPC::Event::ExtraSocket

class IPC::Service
	@closed = false
	@connections = LibIPC::Connections.new
	@service_info = LibIPC::Connection.new

	def initialize(name : String)
		r = LibIPC.ipc_server_init(LibC.environ, pointerof(@service_info), name)
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
			raise Exception.new "cannot initialize the server named #{name}: #{m}"
		end

		# Very important as there are filesystem side-effects.
		at_exit { close }
	end

	def initialize(name : String, &block : Proc(Events|Exception, Nil))
		initialize name
		loop &block
		close
	end

	def add_file_descriptor (fd : Int)
		r = LibIPC.ipc_add_fd(pointerof(@connections), fd)
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
			raise Exception.new "cannot add an arbitrary file descriptor: #{m}"
		end
	end

	# TODO: not implemented in libipc, yet.
	# def del_file_descriptor (fd : Int)
	# 	r = LibIPC.ipc_del_fd(pointerof(@connections), fd)
	# 	if r != 0
	# 		m = String.new LibIPC.ipc_errors_get (r)
	# 		raise Exception.new "cannot remove an arbitrary file descriptor: #{m}"
	# 	end
	# end

	def close
		return if @closed

		r = LibIPC.ipc_server_close(pointerof(@service_info))
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
			raise Exception.new "cannot close the server correctly: #{m}"
		end

		@closed = true
	end

	def finalize
		close
	end

	def wait_event(&block) : Tuple(LibIPC::EventType, IPC::Message, IPC::Connection)
		event = LibIPC::Event.new

		r = LibIPC.ipc_wait_event pointerof(@connections), pointerof(@service_info), pointerof(event)
		if r != 0
			m = String.new LibIPC.ipc_errors_get (r)
			yield IPC::Exception.new "error waiting for a new event: #{m}"
		end

		connection = IPC::Connection.new event.origin.unsafe_as(Pointer(LibIPC::Connection)).value

		pp! event
		message = event.message.unsafe_as(Pointer(LibIPC::Message))
		unless message.null?
			pp! message.value
		end

		return event.type, IPC::Message.new(message), connection
	end

	def loop(&block : Proc(Events|Exception, Nil))
		::loop do
			type, message, connection = wait_event &block

			case type
			when LibIPC::EventType::Connection
				yield IPC::Event::Connection.new connection

			when LibIPC::EventType::NotSet
				yield IPC::Exception.new "even type not set"

			when LibIPC::EventType::Error
				yield IPC::Exception.new "even type indicates an error"

			when LibIPC::EventType::ExtraSocket
				yield IPC::Event::ExtraSocket.new message, connection

			when LibIPC::EventType::Message
				yield IPC::Event::Message.new message, connection

			when LibIPC::EventType::Disconnection
				yield IPC::Event::Disconnection.new connection
			end
		end
	end
end

