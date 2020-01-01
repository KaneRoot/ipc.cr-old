require "./lowlevel"
require "./message"
require "./event"
require "./service"
require "./connection"


class IPC::Client < IPC::Connections
	@connection : IPC::Connection

	def initialize(name : String)
		super()
		@connection = IPC::Connection.new name
		self << @connection
	end

	def initialize(name : String, &block : Proc(IPC::Event::Events|Exception, Nil))
		initialize name
		::loop &block
		close
	end

	def send(*args)
		@connection.send *args
	end

	def read(*args)
		@connection.read *args
	end

	# sanitizer
	def fd
		@connection.fd
	end

	def loop(&block : Proc(IPC::Event::Events|Exception, Nil))
		super(nil, &block)
	end

	def close
		@connection.close
	end
end
