require 'rubygems'
require 'mysql'
require 'date'
require 'csv'
require 'dotenv'

Dotenv.load

names = []

db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')
results = db.query("SELECT position, name, salary, rotowire_mp, numberfire_mp, rotowire_fdp, numberfire_fdp, opp, over_under, spread from oconnor where date = '#{Date.today}'")

CSV.open("todayspool.csv", "w") do |csv|
  csv << ["position", "name", "salary", "rotowire_mp", "numberfire_mp", "rotowire_fdp", "numberfire_fdp", "opp", "over_under", "spread"]

  results.each do |result|
    csv << ["#{result[0]}", "#{result[1]}", "#{result[2]}", "#{result[3]}", "#{result[4]}", "#{result[5]}", "#{result[6]}", "#{result[7]}", "#{result[8]}", "#{result[9]}"]
  end
end

puts names
