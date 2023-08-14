#!/usr/bin/ruby
require "io/console"
require "open-uri"
require "rexml"
require "paint"
class Array
  def +(_thing_or_array)
    if(_thing_or_array.is_a?(Array))
       _thing_or_array.each do |thing|
         self << thing
       end
    else
      self << _thing_or_array
    end
  end
end

class InputError < IOError; end
PROMPT=Paint["> ", [255, 20, 30], :bold, :blink]
CURSOR=Paint["->", :yellow, :bold]
EOF="\003"
R_IO=IO.new(0)
W_IO=IO.new(1, "w")
$urls = []
COMMANDS=[]
CONTENT=[]
WHAT_TO_PRINT=[]
$cursor_pos=0

def usage(usage_blink=false)
  Paint[<<-USE, "#a27ff0", :bold, (:rapid_blink if usage_blink)]
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

#blink if user did something not allowed
def ensure_help_not_printed_twice(help_blink=false) 
  if COMMANDS.last != "help"
    W_IO << usage(help_blink)
    COMMANDS << "help"
  end
end

# \e[A moves the cursor up one line
# \e[B moves the cursor down one line
# \e[K clear from the cursor to end of line
def getCommand()
  command = R_IO.getch
  case command
  when "h"
    ensure_help_not_printed_twice()
    getCommand()
  when "r"
    ask
    COMMANDS << "read"
  when "c"
    $cursor_pos+=1
    W_IO << "\e[A" * (CONTENT.length * 2);
    i = CONTENT.length * 2;
    while(i > 0)
      W_IO << "\e[K";
                  W_IO << "\e[B";
      i -= 1
    end
    W_IO << "\e[A" * (CONTENT.length * 2);
  when EOF || Errno::SIGINT
    exit
  else
    ensure_help_not_printed_twice(true)
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
		items = channel.get_elements("item")
    CONTENT.clear
    CONTENT << "\t\tfrom <<#{Paint[channelTitle, [23, 170, 0]]}>>\t\t\n"
		items.each_with_index do |thing, i|
			tTitle = thing.elements["title"].text
      CONTENT.push " #{$cursor_pos == i ? CURSOR : "  "} -" << tTitle << "\n" * 2 
    end
		end
		#puts root.attributes
end

def printContent
  WHAT_TO_PRINT.clear
  WHAT_TO_PRINT + CONTENT
  WHAT_TO_PRINT.each_with_index do |line, i|
      W_IO << line
  end
end

W_IO.write usage
ask
while(true) 
  begin
    getInput()
    fetchXML()
    printContent
    getCommand()
  rescue InputError, Errno::ENOENT, REXML::ParseException => e
    STDERR << e.message
    ask("\ntry with a valid RSS url:")
  rescue Interrupt
    puts ""
    exit(0) #exit with no errors
  end
end
