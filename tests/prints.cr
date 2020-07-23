require "./colors"

def important(message : String)
	puts "#{CRED}#{message}#{CRESET}"   if CLI.verbosity > 0
end

def info(message : String)
	puts "#{CGREEN}#{message}#{CRESET}" if CLI.verbosity > 1
end

def debug(message : String)
	puts "#{CBLUE}#{message}#{CRESET}"  if CLI.verbosity > 2
end
