require 'rubygems'
require 'crack'
require 'open-uri'
require 'rest-client'

url='http://en.wikipedia.org/w/api.php?action=opensearch&search=At&namespace=0'

puts Crack::JSON.parse(RestClient.get(url))
