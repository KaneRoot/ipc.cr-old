
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

	struct Switching
		origin : LibC::Int
		dest :   LibC::Int
	end

	struct Switchings
		collection : Switching*
		size : LibC::UInt
	end

	enum MessageType
		ServerClose
		Error
		Data
		LookUp
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
		Switch
		Connection
		Disconnection
		Message
		LookUp
		Timer
	end

	struct Event
		type :     EventType
		origin :   Connection*
		message :  Message*
	end

	struct IPCError
		# This is the size of an enumeration in C.
		error_code : UInt32
		error_message : LibC::Char[8192]
	end

	fun ipc_server_init(env : LibC::Char**, connection : Connection*, sname : LibC::Char*) : IPCError
	fun ipc_server_close(Connection*) : IPCError
	fun ipc_close(Connection*) : IPCError

	# connection to a service
	fun ipc_connection(LibC::Char**, Connection*, LibC::Char*) : IPCError

	fun ipc_read(Connection*, Message*) : IPCError
	fun ipc_write(Connection*, Message*) : IPCError

	fun ipc_wait_event(Connections*, Connection*, Event*, LibC::Double*) : IPCError

	fun ipc_add(Connections*, Connection*) : IPCError
	fun ipc_del(Connections*, Connection*) : IPCError
	fun ipc_add_fd(Connections*, LibC::Int) : IPCError
	fun ipc_del_fd(Connections*, LibC::Int) : IPCError

	fun ipc_connection_gen(Connection*, LibC::UInt, LibC::UInt) : IPCError

	fun ipc_connections_free(Connections*)  # Void
	fun ipc_connections_close(Connections*) # Void

	# This function let the user get the default error message based on the error code.
	# The error message is contained in the IPCError structure, this function should not be used, in most cases.
	fun ipc_errors_get (LibC::Int) : LibC::Char*


	# networkd-related functions
	fun ipc_wait_event_networkd(Connections*, Connection*, Event*, Switchings*, LibC::Double*) : IPCError

	fun ipc_receive_fd (sock : LibC::Int, fd : LibC::Int*) : IPCError
	fun ipc_provide_fd (sock : LibC::Int, fd : LibC::Int ) : IPCError

	fun ipc_switching_add  (switch : Switchings*, fd1 : LibC::Int, fd2 : LibC::Int) # Void
	fun ipc_switching_del  (switch : Switchings*, fd  : LibC::Int                 ) : LibC::Int
	fun ipc_switching_get  (switch : Switchings*, fd  : LibC::Int                 ) : LibC::Int
	fun ipc_switching_free (switch : Switchings*                                  ) # Void

	# non public functions (for testing purposes)
	fun ipc_switching_print (switch : Switchings*) # Void
	fun service_path (path : LibC::Char*, sname : LibC::Char*, index : Int32, version : Int32) : IPCError
	fun ipc_connections_print (Connections*) # Void
end
