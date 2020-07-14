require "option_parser"
require "../src/ipc.cr"
require "./colors"

verbosity = 1
service_name = "pong"
no_response = false

OptionParser.parse do |parser|
	parser.on "-s service_name", "--service-name service_name", "URI" do |optsn|
		service_name = optsn
	end

	parser.on "-n", "--no-response", "Do not provide any response back." do
		no_response = true
	end

	parser.on "-v verbosity", "--verbosity verbosity", "Verbosity (0 = nothing is printed, 1 = only events, 2 = events and messages). Default: 1" do |optsn|
		verbosity = optsn.to_i
	end

	parser.on "-h", "--help", "Show this help" do
		puts parser
		exit 0
	end
end

service = IPC::Server.new (service_name)
service.base_timer = 5000 # 5 seconds
service.timer      = 5000 # 5 seconds

service.loop do |event|
	case event
	when IPC::Event::Timer
		if verbosity >= 1
			puts "#{CORANGE}IPC::Event::Timer#{CRESET}"
		end
	when IPC::Event::Connection
		if verbosity >= 1
			puts "#{CBLUE}IPC::Event::Connection#{CRESET}, client: #{event.fd}"
		end
	when IPC::Event::Disconnection
		if verbosity >= 1
			puts "#{CBLUE}IPC::Event::Disconnection#{CRESET}, client: #{event.fd}"
		end
	when IPC::Event::MessageSent
		begin
			if verbosity >= 1
				puts "#{CGREEN}IPC::Event::MessageSent#{CRESET}, client: #{event.fd}"
			end
		rescue e
			puts "#{CRED}#{e.message}#{CRESET}"
			service.remove_fd event.fd
		end
	when IPC::Event::MessageReceived
		begin
			if verbosity >= 1
				puts "#{CGREEN}IPC::Event::MessageReceived#{CRESET}, client: #{event.fd}"
				if verbosity >= 2
					m = String.new event.message.payload
					puts "#{CBLUE}message type #{event.message.utype}: #{m} #{CRESET}"
				end
			end
			service.send event.message unless no_response
			if verbosity >= 2 && ! no_response
				puts "#{CBLUE}sending message...#{CRESET}"
			end

		rescue e
			puts "#{CRED}#{e.message}#{CRESET}"
			service.remove_fd event.fd
		end
	else
		if verbosity >= 1
			puts "#{CRED}Exception: message #{event} #{CRESET}"
		end
	end
end
