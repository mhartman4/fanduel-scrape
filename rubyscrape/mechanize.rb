require 'rubygems'
require 'mechanize'

agent = Mechanize.new
page = agent.get('http://google.com/')
#login_form =
pp page
