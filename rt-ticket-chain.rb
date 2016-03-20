#! /usr/bin/env ruby
# -*- encoding : utf-8 -*-

#ticket_id = system ("rt create -t ticket set subject='Ruby script test' Text = 'Что-то сделать' owner = 'Alex' CF-'Order'='2222'")
require 'kwalify'
require 'logger'

def timestamp
	  Time.now.to_i
end

# load config
config = Kwalify::Yaml.load_file('config.yml')

file = 'project.yml'

logfile = File.open("log/#{file}.log", File::WRONLY | File::CREAT)
logger = Logger.new(logfile)
logger.level = Logger::INFO
logger.formatter = proc do |severity, datetime, progname, msg|
  "#{msg}\n"
end

logger.info("Start at #{timestamp}")
logger.info("DryRun!") if config["dryrun"]

# load schema data
schema = Kwalify::Yaml.load_file('schema.yml')
logger.info("Loaded schema.yml")
logger.info("Start validator")

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
logger.info("Start ticket creation...")
rt_ticket_id = 100 #Ticket number for dryrun

tickets.each do |ticket|
	rt = "rt create -t ticket set"
	ticket.keys.each do |param|
		 rt << " #{param}=\"#{ticket[param]}\"" if config["to_ticket"].include?(param) and ticket[param] 
	end
	
	if config["dryrun"]
		logger.info(rt)
		puts rt 
		rt_ticket_id += 1
	else
		logger.info(rt)
		respond = system (rt) 
		logger.info("From remote rt: #{respond}")
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
				rt = "rt link #{param} #{ticket["rt_ticket_id"]} #{linked_ticket}" if linked_ticket != ticket["rt_ticket_id"]
				if config["dryrun"]
					logger.info(rt)
					puts rt
				else
					logger.info(rt)
					system(rt)
				end
			end
		end
	end 
end

logger.info("Finished #{timestamp}")
