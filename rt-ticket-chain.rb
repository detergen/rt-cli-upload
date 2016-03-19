#! /usr/bin/env ruby
# -*- encoding : utf-8 -*-
require 'yaml'

#ticket_id = system ("rt create -t ticket set subject='Ruby script test' Text = 'Что-то сделать' owner = 'Alex' CF-'Order'='2222'")
ticket_id = '# Ticket 124 created.'
puts ticket_id.gsub!(/\D/, "")  if ticket_id.match(/\# Ticket \d+ created\./)
file = 'test1.yml'
#file = 'project.yml'

#thing = YAML.load_file('project.yml')

#Load and testing YAML
begin
	tickets = YAML.load_file(file) 
rescue Exception 
	puts "failed to read #{file}: #{$!}"
end

#puts tickets.inspect

to_ticket = ["Subject","Text","Owner","Queue","Due"]

def param_wrap (param,value)
end


tickets.each do |ticket|
	rt = "rt create -t ticket set"
	ticket.keys.each do |param|
		 rt <<  " " + param + "=\"" + "#{ticket[param]}" + "\"" if to_ticket.include?(param)
	end
	puts rt
	respond = '# Ticket 4444 created.'
	ticket_id = respond.gsub!(/\D/, "")  if respond.match(/\# Ticket \d+ created\./)
	ticket[:ticket_id] = ticket_id
end 

puts tickets.inspect



