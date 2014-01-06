require 'rubygems'
require 'mysql'
require 'date'
require 'csv'
require 'dotenv'

Dotenv.load

names = []

db = Mysql.new('127.0.0.1','root',ENV["SQL_PASSWORD"],'fanduel')
results = db.query("SELECT name from oconnor where date = '#{Date.today}'")

CSV.open("/Users/michael-orderup/SkyDrive/Project Mellon/mellon_projections.csv", "w") do |csv|
  csv << ["name", "mellon"]

  results.each do |result|
    csv << ["#{result[0]}", ""]
  end
end

