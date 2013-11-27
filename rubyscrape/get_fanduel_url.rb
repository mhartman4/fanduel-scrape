require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'CSV'
require 'mechanize'

agent = Mechanize.new
page = agent.get('http://fanduel.com/league/daily_nba_freeroll')
fanduel_url = page.uri.to_s
puts fanduel_url


