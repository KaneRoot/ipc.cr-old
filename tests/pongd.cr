require "option_parser"
require "../src/ipc.cr"
require "./prints.cr"

class CLI
	class_property service_name = "pong"
	class_property verbosity    = 1
	class_property timer        = 30_000
	class_property no_response  = false
end

OptionParser.parse do |parser|
	parser.on "-s service_name", "--service-name service_name", "URI" do |optsn|
		CLI.service_name = optsn
	end

	parser.on "-n", "--no-response", "Do not provide any response back." do
		CLI.no_response = true
	end

	parser.on "-t timer", "--timer ms", "Timer in ms. Default: 30 000" do |optsn|
		CLI.timer = optsn.to_i
	end


	parser.on "-v verbosity", "--verbosity verbosity", "Verbosity (0 = nothing is printed, 1 = only events, 2 = events and messages). Default: 1" do |optsn|
		CLI.verbosity = optsn.to_i
	end

	parser.on "-h", "--help", "Show this help" do
		puts parser
		exit 0
	end
end

def main
	service = IPC::Server.new CLI.service_name
	service.base_timer = CLI.timer # default: 30 seconds
	service.timer      = CLI.timer # default: 30 seconds

	service.loop do |event|
		# service.pp
		case event
		when IPC::Event::Timer
			info "IPC::Event::Timer"
		when IPC::Event::Connection
			info "IPC::Event::Connection, client: #{event.fd}"
		when IPC::Event::Disconnection
			info "IPC::Event::Disconnection, client: #{event.fd}"
		when IPC::Event::MessageSent
			begin
				info "IPC::Event::MessageSent, client: #{event.fd}"
			rescue e
				important "#{e.message}"
				service.remove_fd event.fd
			end
		when IPC::Event::MessageReceived
			begin
				info "IPC::Event::MessageReceived, client: #{event.fd}"
				m = String.new event.message.payload
				debug "message type #{event.message.utype}: #{m}"

				unless CLI.no_response
					service.send event.message
					debug "sending message..."
				end

			rescue e
				important "#{e.message}"
				service.remove_fd event.fd
			end
		else
			important "Exception: message #{event}"
		end
	end
end

main
