require 'net/https'
http = Net::HTTP.new('www.google.com', 443)
http.use_ssl = true
path = '/accounts/ClientLogin'
data = \
