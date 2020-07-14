require "../src/ipc.cr"

client = IPC::Client.new "pong"

server_fd = client.server_fd

if server_fd.nil?
	puts "there is no server_fd!!"
	exit 1
end

message = IPC::Message.new server_fd, 1, 42.to_u8, "salut ça va ?"

client.send message

client.loop do |event|
	case event
	when IPC::Event::MessageReceived
		puts "\033[32mthere is a message\033[00m"
		puts event.message.to_s
		client.close
		exit
	end
end
