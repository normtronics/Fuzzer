require 'gli'

include GLI::App

program_desc 'Time to fuzz the web'

pre do |global_options,command,options,args|
  
end

#Create a discover file and include it 
command :discover do |c|
  puts 'add'
end

#Create a test file and include it
command :test do |c|
  puts 'add'
end

exit run(ARGV)