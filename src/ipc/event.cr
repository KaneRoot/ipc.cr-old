require "./lowlevel"
require "./message"
require "./connection"

class IPC::Event
	alias Events = IPC::Event::Timer | IPC::Event::Connection | IPC::Event::Disconnection | IPC::Event::Message | IPC::Event::ExtraSocket | IPC::Event::Switch | IPC::Event::LookUp

	class Timer
	end

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

	class Switch < IPC::Event::Message
	end

	class LookUp < IPC::Event::Message
	end
end

