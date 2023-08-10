#!/usr/bin/ruby
require "open-uri"
require "rexml"

class InputError < IOError; end
CURSOR="> "
$urls = []

def ask(qstn="include url:")
  $urls.clear
  puts qstn
end

def getInput()
  print CURSOR
  urls = STDIN.readline
  urls = urls.split " "
  urls.each do |u| 
    u = u.chomp("\n")
    $urls.push(u) 
  end
  $urls.first
end

def idle()
  input = gets
end


def fetchXML
  url = $urls[0]
  file = URI.open(url) 
  doc = REXML::Document.new(file)
  root = doc.root
  channel = root.elements["channel"]
  channelTitle = channel.elements["title"].text
  puts "\t\tfrom <<#{channelTitle}>>\t\t\n"
  items = channel.get_elements("item")
  items.each_with_index do |thing, i|
    tTitle = thing.elements["title"].text
    puts tTitle
  end
  #puts root.attributes
end

while(true) 
  ask
  begin
    getInput
    fetchXML()
    idle()
  rescue InputError, Errno::ENOENT, REXML::ParseException => e
    STDERR << e.message
    ask("try with a valid RSS url:")
  end
end
