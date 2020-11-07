
@[Link("ipc")]
lib LibIPC
	INFTIM = -1

	enum ConnectionType
		IPC       # IO op. are handled by libipc.
		External  # IO op. are handled by the libipc user app.
		Server    # Should listen and accept new IPC users.
		Switched  # IO op. are handled by callbacks.
	end

	struct Connection
		type :         ConnectionType  #
		more_to_read : Int16*          #
		spath :        LibC::Char*     # [4096] # [PATH_MAX]
	end

	struct Pollfd
		fd :      LibC::Int
		events :  LibC::Short
		revents : LibC::Short
	end

	struct Switching
		origin : LibC::Int
		dest :   LibC::Int
		orig_cb_in  : (Int32, Pointer(Message), Int16*) -> ConnectionType
		orig_cb_out : (Int32, Pointer(Message)) -> ConnectionType
		dest_cb_in  : (Int32, Pointer(Message), Int16*) -> ConnectionType
		dest_cb_out : (Int32, Pointer(Message)) -> ConnectionType
	end

	struct Switchings
		collection : Switching*
		size : LibC::UInt
	end

	struct Ctx
		cinfos :   Connection*
		pollfd :   Pollfd*
		size :     LibC::UInt64T
		tx :       Messages
		switchdb : Switchings
	end

	enum MessageType
		ServerClose
		Error
		Data
		LookUp
	end

	# Messages are stored in lists within the libipc before being sent.
	struct Messages
		messages :  Message*
		size :      LibC::UInt64T
	end

	struct Message
		type :       UInt8        # Internal message type.
		user_type :  UInt8        # User-defined message type.
		fd :         LibC::Int    # fd of the sender.
		length :     LibC::UInt   # Payload length.
		payload :    LibC::Char*  #
	end

	enum EventType
		NotSet        #
		Error         #
		ExtraSocket   # Message received from a non IPC socket.
		Switch        # Message to send to a corresponding fd.
		Connection    # New user.
		Disconnection # User disconnected.
		Message       # New message.
		LookUp        # Client asking for a service through ipcd.
		Timer         # Timeout in the poll(2) function.
		Tx            # Message sent.
	end

	struct Event
		type :     EventType   #
		index :    LibC::UInt  # Index of the sender in the ipc_ctx structure.
		origin :   LibC::Int   # fd of the sender.
		message :  Message*    # Pointer to the reveiced message.
	end

	struct IPCError
		# This is the size of an enumeration in C.
		error_code : UInt32
		error_message : LibC::Char[8192]
	end

	# Connection functions.
	# Context is allocated, ipcd is requested and the connection/initialisation is performed.
	fun ipc_server_init(ctx : Ctx*, sname : LibC::Char*) : IPCError
	fun ipc_connection(Ctx*, LibC::Char*, Int32*) : IPCError
	fun ipc_connection_switched(Ctx*, LibC::Char*, LibC::Int, Pointer(LibC::Int)) : IPCError

	# ipc_message_copy: pm, @fd, @mtype, @utype, @payload
	fun ipc_message_copy(Message*, LibC::Int, UInt8, UInt8, LibC::Char*, Int32)

	# Closing connections.
	fun ipc_close(ctx : Ctx*, index : LibC::UInt64T) : IPCError
	fun ipc_close_all(ctx : Ctx*) : IPCError

	fun ipc_ctx_free(Ctx*)        # Void

	# Loop function.
	fun ipc_wait_event(Ctx*, Event*, LibC::Int*) : IPCError

	# Adding and removing file discriptors to read.
	fun ipc_add(Ctx*, Connection*, Pollfd*) : IPCError
	fun ipc_del(Ctx*, LibC::UInt) : IPCError
	fun ipc_add_fd(Ctx*, LibC::Int) : IPCError
	fun ipc_add_fd_switched(Ctx*, LibC::Int) : IPCError
	fun ipc_del_fd(Ctx*, LibC::Int) : IPCError

	# Sending a message (will wait the fd to become available for IO operations).
	fun ipc_write(Ctx*, Message*) : IPCError

	# Sending a message NOW.
	# WARNING: unbuffered send do not wait the fd to become available.
	fun ipc_write_fd(Int32, Message*) : IPCError

	# This function let the user get the default error message based on the error code.
	# The error message is contained in the IPCError structure, this function should not be used, in most cases.
	fun ipc_errors_get (LibC::Int) : LibC::Char*

	# Exchanging file descriptors (used with ipcd on connection).
	fun ipc_receive_fd (sock : LibC::Int, fd : LibC::Int*) : IPCError
	fun ipc_provide_fd (sock : LibC::Int, fd : LibC::Int ) : IPCError

	# To change the type of a fd.
	fun ipc_ctx_fd_type(Ctx*, LibC::Int, LibIPC::ConnectionType) : LibC::Int

	enum IPCCB
		NoError       #
		Closing       #
		Error         #
		ParsingError  #
		Ignore        #
	end

	# Changing the callbacks for switched fd.
	# ipc_switching_callbacks: ctx, fd
	# , enum ipccb cb_in  (fd, *ipc_message)
	# , enum ipccb cb_out (fd, *ipc_message)
	fun ipc_switching_callbacks(Ctx*, LibC::Int,
		(LibC::Int, LibIPC::Message*, Int16* -> LibIPC::IPCCB),
		(LibC::Int, LibIPC::Message* -> LibIPC::IPCCB))

	fun ipc_ctx_switching_add  (ctx : Ctx*, fd1 : LibC::Int, fd2 : LibC::Int)       # Void
	fun ipc_ctx_switching_del  (ctx : Ctx*, fd  : LibC::Int)                        : LibC::Int
	fun ipc_switching_add  (switch : Switchings*, fd1 : LibC::Int, fd2 : LibC::Int) # Void
	fun ipc_switching_del  (switch : Switchings*, fd  : LibC::Int                 ) : LibC::Int
	fun ipc_switching_get  (switch : Switchings*, fd  : LibC::Int                 ) : LibC::Int
	fun ipc_switching_free (switch : Switchings*                                  ) # Void

	# non public functions
	fun ipc_read(ctx : Ctx*, index : LibC::UInt, message : Message*) : IPCError
	fun ipc_read_fd(fd : Int32, message : Message*) : IPCError

	# for testing purposes
	fun ipc_switching_print (switch : Switchings*) # Void
	fun service_path (path : LibC::Char*, sname : LibC::Char*, index : Int32, version : Int32) : IPCError
	fun ipc_ctx_print (Ctx*) # Void
end
