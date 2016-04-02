#! /usr/bin/env ruby
# -*- encoding : utf-8 -*-

require 'kwalify'
require 'logger'

def timestamp
	  Time.now.strftime("%F %T") 
end

# load config
config = Kwalify::Yaml.load_file('config.yml')

file = ARGV[0]
abort("Can't find file #{file}") if !File.file?(file)

#Log setup
logfile = File.open("log/#{file}.log", File::WRONLY | File::CREAT)
$logger = Logger.new(logfile)
$logger.level = Logger::INFO
$logger.formatter = proc do |severity, datetime, progname, msg|
  "#{msg}\n"
end

def llogger (s)
	$logger.info(s)
	puts s
end


llogger("Start at #{timestamp}")
llogger("DryRun!") if config["dryrun"]

# load schema data
schema = Kwalify::Yaml.load_file('schema.yml')
llogger("Loaded schema.yml")
llogger("Start validator")

# create validator
validator = Kwalify::Validator.new(schema)

#file = 'test1.yml'
tickets = Kwalify::Yaml.load_file(file)

## create parser with validator
## (if validator is ommitted, no validation executed.)
parser = Kwalify::Yaml::Parser.new(validator)

document = parser.parse_file(file)

## show errors if exist
errors = parser.errors()
if errors && !errors.empty?
  for e in errors
    puts "#{e.linenum}:#{e.column} [#{e.path}] #{e.message}"
  end
  abort("Please check file #{file}")
end


#Create tickets and get real rt ticket id
llogger("Start ticket creation...")
rt_ticket_id = 100 #Ticket number for dryrun

tickets.each do |ticket|
	rt = "rt create -t ticket set"
	ticket.keys.each do |param|
		 rt << " #{param}=\"#{ticket[param]}\"" if config["to_ticket"].include?(param) and ticket[param] 
	end
	
	if config["dryrun"]
		llogger(rt)
		puts rt 
		rt_ticket_id += 1
	else
		llogger(rt)
		respond = `#{rt}`
		llogger("RT server: #{respond}")
		rt_ticket_id = respond.gsub!(/\D/, "")  if respond.match(/\# Ticket \d+ created\./)
	end
		ticket["rt_ticket_id"] = rt_ticket_id
end 

#Create links beetwen tickets
tickets.each do |ticket| #All tickets array
	ticket.keys.each do |param| #Every param in array row
		if config["to_link"].include?(param) and ticket[param]#look for dependencies
			ticket[param].each do |link| #Every value in parametr
				linked_ticket = tickets.find{|t| t["Ticket"] == link}["rt_ticket_id"]
				rt = "rt link #{ticket["rt_ticket_id"]} #{param} #{linked_ticket}" if linked_ticket != ticket["rt_ticket_id"]
				if config["dryrun"]
					llogger(rt)
				else
					llogger("Try to create link:#{rt}")
					respond = `#{rt}`
				end
			end
		end
	end 
end

llogger("Finished #{timestamp}")
