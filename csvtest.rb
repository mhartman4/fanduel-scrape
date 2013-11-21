require 'csv'
=begin
csv_text = File.read('playerlist.csv')
csv = CSV.parse(csv_text, :headers => true)
csv.each do |row|
  puts row["name"]
end
=end


CSV.foreach("playerlist.csv", :headers => true) do |row|
  puts row["name"]
end

