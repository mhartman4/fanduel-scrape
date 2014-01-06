require "rinruby"

def print_summary(routput)

end


r=RinRuby.new(:echo=>false)
=begin
#sample_size = 10
r_output = r.pull 'load("/Users/michael-orderup/Downloads/computers.RData")'
r_output = r.pull 'summary(computers)'
r_output.each do |row|
  puts row
end
=end
r.eval 'load("/Users/michael-orderup/Downloads/computers.RData")'
r.pull 'summary(computers)'
r_output = r.pull 'random_sample = computers[sample(1:length(computers $age),450),]'
puts r_output

