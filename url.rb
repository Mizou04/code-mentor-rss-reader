#!/usr/bin/ruby
require "io/console"
require "open-uri"
require "rexml"

class InputError < IOError; end
PROMPT="> "
CURSOR="->"
EOF="\003"
R_IO=IO.new(0)
W_IO=IO.new(1, "w")
$urls = []
COMMANDS=[]

def usage
  <<-USE
  this is a simple RSS feed reader using terminal as UI
  commands(after running): 
                 h:     print this text
                 r:     to restart the program
    up/down arrows:     to move cursor

  USE
end

def ask(qstn="include url:")
  $urls.clear
  W_IO << qstn << "\n"
end

def getInput()
  print PROMPT
  urls = gets
  urls = urls.split " " if urls.is_a? String
  urls.each do |u| 
    $urls.push(u) 
  end
  $urls.first
end

def getCommand()
  command = R_IO.getch
  case command
  when "h"
    if COMMANDS.last != "help"
      W_IO << usage
      COMMANDS << "help"
    end
    getCommand()
  when "r"
    ask
    COMMANDS << "read"
  when EOF
    exit
  else
    if COMMANDS.last != "help"
      W_IO << usage
      COMMANDS << "help"
    end
    getCommand()
  end
end

def fetchXML
  $urls.each do |url|
		file = URI.open(url) 
		doc = REXML::Document.new(file)
		root = doc.root
		channel = root.elements["channel"]
		channelTitle = channel.elements["title"].text
		W_IO << "\t\tfrom <<#{channelTitle}>>\t\t\n"
		items = channel.get_elements("item")
		items.each_with_index do |thing, i|
			tTitle = thing.elements["title"].text
      W_IO << "  -" << tTitle << "\n" * 2
    end
		end
		#puts root.attributes
end

W_IO.write usage
ask
while(true) 
  begin
    getInput()
    fetchXML()
    getCommand()
  rescue InputError, Errno::ENOENT, REXML::ParseException => e
    STDERR << e.message
    ask("try with a valid RSS url:")
  rescue Interrupt
    puts ""
    exit(0) #exit with no errors
  end
end
