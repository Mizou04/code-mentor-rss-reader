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
$channelTitle = ""
$cursor_pos=0
$chunk_index=0
$chunk_size=3

def usage(usage_blink=false)
  Paint[<<-USE, "#a27ff0", :bold, (:rapid_blink if usage_blink)]
  this is a simple RSS feed reader using terminal as UI
  commands(after running): 
                 h:     print this text
                 r:     to restart the program
               k/j:     up/down
                 q:     to quit the program

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

def clearRenderedItems()
  _lines_count = (WHAT_TO_PRINT.length * 2)
  _lines_count += usage.count("\n") + 1 if(COMMANDS.last == "help")
  W_IO << "\e[A" * _lines_count;
  i = _lines_count;
  while(i > 0)
    W_IO << "\e[K" << "\e[B"
    i -= 1
  end
  W_IO << "\e[A" * _lines_count;
  COMMANDS.pop()
end

def clearItems()
  WHAT_TO_PRINT.clear
end

def chooseItems(i=$chunk_index, n=$chunk_size)
  clearItems()
  WHAT_TO_PRINT + CONTENT.slice(i, n)
  WHAT_TO_PRINT << "(+) load more.." if(i+n < CONTENT.length)
end

def renderItems
  WHAT_TO_PRINT.each_with_index do |line, i|
      W_IO << " #{$cursor_pos == i ? CURSOR : "  "} +" << line << "\n" * 2 
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
  when "m"
    if( WHAT_TO_PRINT.last =~ /load more/ &&
        $cursor_pos == WHAT_TO_PRINT.index(WHAT_TO_PRINT.last) )
      clearRenderedItems()
      clearItems()
      $chunk_index += 1
      chooseItems($chunk_index, $chunk_size)
      renderItems()
      getCommand()
    end
  when "r"
    ask
    COMMANDS << "read"
  when "k"
    $cursor_pos-=1
    if($cursor_pos < 0)
      $cursor_pos = WHAT_TO_PRINT.length - 1
    end
    clearRenderedItems()
    renderItems()
    getCommand()
  when "j"
    $cursor_pos+=1
    if($cursor_pos >= WHAT_TO_PRINT.length)
      $cursor_pos = 0
    end
    clearRenderedItems()
    renderItems()
    getCommand()
  when "c"
    clearRenderedItems()
  when EOF
  #when Errno::SIGINT
  when "q"
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
		$channelTitle = channel.elements["title"].text
		items = channel.get_elements("item")
    CONTENT.clear
		items.each_with_index do |thing, i|
			tTitle = thing.elements["title"].text
      CONTENT.push(tTitle)
    end
		end
		#puts root.attributes
end

def printTitle
  W_IO << "\t\tfrom #{Paint[$channelTitle, [23, 170, 50], :bold]}\t\t\n\n"
end

W_IO.write usage
ask
while(true) 
  begin
    getInput()
    previous_title = $channelTitle
    fetchXML()
    printTitle() unless $channelTitle == previous_title
    chooseItems();
    renderItems()
    getCommand()
  rescue InputError, Errno::ENOENT, REXML::ParseException => e
    STDERR << e.message
    ask("\ntry with a valid RSS url:")
  rescue Interrupt
    puts ""
    exit(0) #exit with no errors
  end
end
