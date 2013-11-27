require 'rubygems'
require 'tiny_tds'

client = TinyTds::Client.new(:username => 'michar783_fd', :password => 'liberace', :host => 'mysql28.freehostia.com', :port => 3306, :database => 'michar783_fd')

puts "hello"
#MAKE IT LOOK PRETTY. ap = awesome_print command
#ap MsSQLClient.execute(sql)
