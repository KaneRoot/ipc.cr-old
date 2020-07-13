
class IPC::Event
	alias Events = IPC::Event::Timer |
		IPC::Event::Error |
		IPC::Event::Connection |
		IPC::Event::Disconnection |
		IPC::Event::MessageReceived |
		IPC::Event::ExtraSocket |
		IPC::Event::Switch |
		IPC::Event::LookUp |
		IPC::Event::MessageSent
end

class IPC::Event::Timer < IPC::Event
	def initialize
	end
end

class IPC::Event::Base < IPC::Event
	property fd    : Int32
	property index : UInt32

	def initialize(@fd, @index) 
	end
end

class IPC::Event::Connection < IPC::Event::Base
end

class IPC::Event::Disconnection < IPC::Event::Base
end

class IPC::Event::Error < IPC::Event::Base
end

class IPC::Event::MessageReceived < IPC::Event::Base
	getter message : ::IPC::Message

	def initialize(@fd, @index, @message)
	end
end

class IPC::Event::ExtraSocket < IPC::Event::Base
end

class IPC::Event::Switch < IPC::Event::Base
end

class IPC::Event::LookUp < IPC::Event::Base
end

class IPC::Event::MessageSent < IPC::Event::Base
end

