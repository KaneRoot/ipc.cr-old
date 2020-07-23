require "option_parser"
require "../src/ipc.cr"
require "./prints.cr"

class CLI
	class_property service_name           = "pong"
	class_property message      : String? = nil
	class_property type                   = 1
	class_property user_type              = 42
	class_property verbosity              = 1
	class_property rounds                 = 1
end

OptionParser.parse do |parser|
	parser.on "-s service_name", "--service-name service_name", "URI" do |optsn|
		CLI.service_name = optsn
	end

	parser.on "-v verbosity", "--verbosity verbosity", "Verbosity (0 = nothing is printed, 1 = only events, 2 = events and messages). Default: 1" do |optsn|
		CLI.verbosity = optsn.to_i
	end

	parser.on "-t message_type",
		"--type message_type",
		"(internal) message type." do |opt|
		CLI.type = opt.to_i
	end

	parser.on "-u user_message_type",
		"--user-type user_message_type",
		"Message type." do |opt|
		CLI.user_type = opt.to_i
	end


	parser.on "-r rounds", "--rounds count", "Number of messages sent." do |opt|
		CLI.rounds = opt.to_i
	end

	parser.on "-m message", "--message m", "Message to sent." do |opt|
		CLI.message = opt
	end

	parser.on "-h", "--help", "Show this help" do
		puts parser
		exit 0
	end
end

def main
	client = IPC::Client.new CLI.service_name
	client.base_timer = 30_000 # 30 seconds
	client.timer      = 30_000 # 30 seconds

	server_fd = client.server_fd
	if server_fd.nil?
		puts "there is no server_fd!!"
		exit 1
	end

	nb_messages_remaining = CLI.rounds

	# Listening on STDIN.
	client << 0

	client.loop do |event|
		case event
		when IPC::Event::ExtraSocket
			puts "extra socket fd #{event.fd}"
			info "reading on #{event.fd}"
			if event.fd == 0
				puts "reading on STDIN"
			end

			mstr = if CLI.message.nil?
				if event.fd == 0 STDIN.gets || "STDIN failed!" else "coucou" end
			else
				CLI.message.not_nil!
			end

			CLI.rounds.times do |i|
				client.send server_fd.not_nil!, CLI.user_type.to_u8, mstr.to_slice
			end
		when IPC::Event::MessageReceived
			nb_messages_remaining -= 1
			info "new message from #{event.fd}: #{event.message.to_s}, remaining #{nb_messages_remaining}"
			if nb_messages_remaining == 0
				exit 0
			end
		when IPC::Event::Disconnection
			info "Disconnection from #{event.fd}"
			if event.fd == 0
				client.remove_fd 0
			end
		else
			info "unhandled event: #{event.class}"
		end
	end
end

main
