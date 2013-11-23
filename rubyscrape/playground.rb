require 'date'

d = Date.today
d = Date.parse(d).strftime("%m/%d/%Y")

puts d
