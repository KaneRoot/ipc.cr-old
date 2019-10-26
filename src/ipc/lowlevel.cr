
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
		UsockConnectConnect
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

	fun ipc_server_init(env : LibC::Char**, connection : Connection*, sname : LibC::Char*) : LibC::Int
	fun ipc_server_close(Connection*) : LibC::Int
	fun ipc_close(Connection*) : LibC::Int

	# connection to a service
	fun ipc_connection(LibC::Char**, Connection*, LibC::Char*) : LibC::Int

	fun ipc_read(Connection*, Message*) : LibC::Int
	fun ipc_write(Connection*, Message*) : LibC::Int

	fun ipc_wait_event(Connections*, Connection*, Event*, LibC::Long*) : LibC::Int

	fun ipc_add(Connections*, Connection*) : LibC::Int
	fun ipc_del(Connections*, Connection*) : LibC::Int
	fun ipc_add_fd(Connections*, LibC::Int) : LibC::Int
	fun ipc_del_fd(Connections*, LibC::Int) : LibC::Int

	fun ipc_connection_copy(Connection*) : Connection*
	fun ipc_connection_eq(Connection*, Connection*) : LibC::Int

	fun ipc_connection_gen(Connection*, LibC::UInt, LibC::UInt)

	fun ipc_connections_free(Connections*)
	fun ipc_connections_close(Connections*)
	fun ipc_get(Connections*)
	fun ipc_errors_get (LibC::Int) : LibC::Char*


	# networkd-related functions
	fun ipc_wait_event_networkd(Connections*, Connection*, Event*, Switchings*, LibC::Long*) : LibC::Int

	fun ipc_receive_fd (sock : LibC::Int, fd : LibC::Int*) : LibC::Int
	fun ipc_provide_fd (sock : LibC::Int, fd : LibC::Int) : LibC::Int

	fun ipc_switching_add   (switch : Switchings*, fd1 : LibC::Int, fd2 : LibC::Int)
	fun ipc_switching_del   (switch : Switchings*, fd  : LibC::Int                 ) : LibC::Int
	fun ipc_switching_get   (switch : Switchings*, fd  : LibC::Int                 ) : LibC::Int
	fun ipc_switching_free  (switch : Switchings*                                  ) : LibC::Int
	fun ipc_switching_print (switch : Switchings*)

	# non public functions (for testing purposes)
	fun service_path (path : LibC::Char*, sname : LibC::Char*, index : Int32, version : Int32) : LibC::Int
	fun log_get_logfile_dir (buf : LibC::Char*, size : LibC::UInt) : LibC::Char*
	fun log_get_logfile_name (buf : LibC::Char*, size : LibC::UInt)
	fun ipc_connections_print(Connections*)
end
