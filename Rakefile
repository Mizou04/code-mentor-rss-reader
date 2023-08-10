require "rss"
require "bundler"

Bundler::GemHelper.install_tasks
=begin
task :setup_lib do
  lib_loc = File.expand_path(File.join(__dir__, "lib"))
  puts $:.unshift(lib_loc) unless $:.include?(lib_loc)
end

task :build => :setup_lib do
  program =%q(def hello
    puts \"world\"
  end
  hello)

  sh "echo \"#{program}\" > app/main.rb" 
end
=end
